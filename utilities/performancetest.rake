require 'rubygems'
require 'bundler'
require 'highline/import'

begin
  Bundler.setup(:default, :development, :test)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'ripple'
require "rake/testtask"

namespace :environment do
  task :app do
    if ENV['RACK_ENV'].nil?
      ENV['RACK_ENV'] = 'local'
    end
    require File.join(File.dirname(__FILE__), "app", "app")
  end
end

namespace :test do
  #Usage: bundle exec rake --rakefile performancetest.rake test:smoketest["performancetest.yml"]
  task :smoketest, [:conf] => ['environment:app'] do |t, args|
    conf = SettingsHash.new(args.conf)
    stats = File.open(conf[:outfile], "a")

    user_pool = load_users conf[:infile]
    session_counter = 0
    window_counter = 0
    start_time = Time.now
    end_time = start_time + conf[:total_time].seconds

    user_pool.each { |u|
      elapsed = timer do
        conf[:operations].each { |operation|
          login u if operation == 'login'
          dashboard u if operation == 'dashboard'
          settings u if operation == 'settings'
          writemeasures u, conf[:measure_writes] if operation == 'writemeasures'
          readmeasures u, conf[:measure_reads] if operation == 'readmeasures'
        }
      end

      log.write "One session took #{elapsed} ms\n"

      stats.write "#{Time.now.strftime("%Y%m%d%H%M%S")},#{elapsed}\n"
    }
  end

  def login u
    RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}users/index/email_bin/#{u[:email]}", {"Content-type" => "application/json" })
    res = RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}users/keys/#{u[:uid]}", {"Content-type" => "application/json" })
    RestClient.put(riak_url + "buckets/#{Ripple.config[:namespace]}users/keys/#{u[:uid]}?returnbody=true", JSON.parse(res).to_json, {"Content-type" => "application/json" })
    RestClient.put(riak_url + "buckets/#{Ripple.config[:namespace]}users/keys/#{u[:uid]}?returnbody=true", JSON.parse(res).to_json, {"Content-type" => "application/json" })

    RestClient.get(api_url + "v2/health/internal/user/#{u[:uid]}", {"Content-type" => "application/json" })
    RestClient.put(api_url + "v2/health/internal/user/#{u[:uid]}", {"name" => u[:name],"email" => u[:email],"phone_numbers" => [],"timezone" => "GMT-8:00"}.to_json, {"Content-type" => "application/json" })
    RestClient.put(api_url + "v2/health/internal/user/#{u[:uid]}", {"name" => u[:name],"email" => u[:email],"phone_numbers" => [],"timezone" => "GMT-8:00"}.to_json, {"Content-type" => "application/json" })
  end

  def dashboard u
    begin; RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}connections/keys/myzeo-#{u[:uid]}", {"Content-type" => "application/json" }); rescue; end
    begin; RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}connections/keys/fitbit-#{u[:uid]}", {"Content-type" => "application/json" }); rescue; end
    begin; RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}connections/keys/withings-#{u[:uid]}", {"Content-type" => "application/json" }); rescue; end
    begin; RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}developers/keys/#{u[:uid]}", {"Content-type" => "application/json" }); rescue; end
    RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}users/keys/#{u[:uid]}", {"Content-type" => "application/json" })

    #TODO: Keep these external w/ oauth?
    RestClient.get(api_url + "v2/health/data?all_measures=true&oauth_token=#{u[:auth_token]}", {"Content-type" => "application/json" })
    RestClient.get(api_url + "v2/health/user?oauth_token=#{u[:auth_token]}", {"Content-type" => "application/json" })
    #RestClient.get(api_url + "v2/health/internal/user/#{u[:uid]}/data?all_measures=true", {"Content-type" => "application/json" })
    #RestClient.get(api_url + "v2/health/internal/user/#{u[:uid]}", {"Content-type" => "application/json" })
  end


  def settings u
    RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}users/keys/#{u[:uid]}", {"Content-type" => "application/json" })
    RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}users/keys/#{u[:uid]}", {"Content-type" => "application/json" })
    RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}mobile_requests/index/user_id_bin/#{u[:uid]}", {"Content-type" => "application/json" })
    RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}email_requests/index/user_id_bin/#{u[:uid]}", {"Content-type" => "application/json" })
    begin; RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}developers/keys/#{u[:uid]}", {"Content-type" => "application/json" }); rescue; end
    RestClient.get(riak_url + "buckets/#{Ripple.config[:namespace]}users/keys/#{u[:uid]}", {"Content-type" => "application/json" })
  end


  def writemeasures u, nmeasures
    nmeasures.to_i.times {
      RestClient.post(api_url + "v2/health/source/foobar_app/data?oauth_token=#{u[:auth_token]}", [{:name => 'Weight', :value => 100+Random.rand(101), :unit => 'lb', :timestamp => Time.now.strftime("%Y%m%d%H%M")}].to_json,{"Content-type" => "application/json" })
    }
  end

  def readmeasures u, nmeasures
    nmeasures.to_i.times {
      RestClient.get(api_url + "v2/health/data/mass?accept=jsonp&oauth_token=#{u[:auth_token]}", {"Content-type" => "application/json" })
    }
  end

  def timer()
    beginning_time = Time.now
    yield
    (Time.now - beginning_time)
  end

  def riak_url
    "http://#{Ripple.config[:host]}:#{Ripple.config[:http_port]}/"
  end

  def api_url
    Server.setting(:api_uri) + "/"
  end

  def load_users infile
    user_pool = []

    File.open(infile).each do |line|
      email, uid, name, auth_token = line.split("|")
      hash = { :email => email, :uid => uid, :name => name, :auth_token => auth_token}
      user_pool.push(hash)
    end

    user_pool
  end
end

namespace :db do
  task :prepop, [:outfile,:nusers,:nmeasures] => ['environment:app'] do |t, args|
    puts "Starting prepopulation, args.nusers: #{args.nusers}, args.nmeasures: #{args.nmeasures}"

    default_password = "testpass"
    Riak.disable_list_keys_warnings = true
    PasswordTools.checks_disabled!
    puts Ripple.config
    require File.join(File.dirname(__FILE__), "test", "support", "models")
    Server.update_global_settings_for('password_reset_required_at', Time.utc(0))

    file = File.open(args.outfile, "w")

    # Create Users
    du = User.spawn(:email => "dev@example.com",
                    :full_name => "Developer",
                    :password => default_password,
                    :password_confirmation => default_password)
    du.verify_email!
    developer = Developer.spawn(:identity_id => du.id)
    developer.approve!

    application = Application.spawn(
        :name => "foobar_app",
        :display_name => "Foo Bar App",
        :developer_id => du.id,
    )

    p = ProductMeasure.new('name' => 'Weight', 'type' => "mass")
    p.application = application
    p.save
    p.commit!

    for u in 1..args.nusers.to_i
      user = User.spawn(:email => "user#{u}@example.com",
                 :full_name => "User_Number#{u}",
                 :password => default_password,
                 :password_confirmation => default_password)
      user.verify_email!

      auth = AuthorizationCode.new(:redirect_uri => 'http://client.example.com',
                                    :scope => '/read/health/data/foobar_app /admin/health/user /admin/health/source/foobar_app')

      auth.user = user
      auth.application = application
      auth_token = auth.grant!

      source = Att::API::Internal::Source.new(Server.setting(:api_uri), user.id, application.name)

      for m in 1..args.nmeasures.to_i
        source.write([{:name => 'Weight', :value => 100+Random.rand(101), :unit => 'lb', :timestamp => Time.now.strftime("%Y%m%d%H%M")}])
      end

      file.write(user.email + "|" + user.id + "|" + user.full_name + "|" + auth_token + "\n")
    end

    # A little visual feedback never hurt anybody
    Ripple.client.buckets.each do |bucket|
      puts "Bucket : #{bucket.name}"
      bucket.keys.each do |key|
        puts "  Key: #{key}"
      end
    end

    file.close unless file == nil

    puts "Done"
  end

  # this task leverages list keys, use on dev systems only
  task :unpop => ['environment:app'] do
    puts "This will destroy all mhealth data on the cluster. Are you sure? (y/n)"
    input = STDIN.gets.strip
    if input != 'y'
      puts "Exiting now."
      next
    end

    puts Ripple.config
    # handle the case where the db may have encrypted values to wipe out
    Ripple::Contrib::Encryption.activate(File.join(ROOT_DIR,'config','encryption.yml'))
    Riak.disable_list_keys_warnings = true
    Connection.destroy_all
    Collection.destroy_all
    Application.destroy_all
    Developer.destroy_all
    User.destroy_all

    prefix = Ripple.config[:namespace]

    buckets = [
      'm_health_models_products',
      'm_health_models_product_lists',
      'm_health_models_daily_logs',
      'm_health_models_users',
      'authorization_codes',
      'applications_icons',
      'global_settings',
      'audit_entries']

    buckets.each do |bucket|
      if prefix != nil and prefix.length > 0
        bucket = prefix + bucket
      end

      Ripple.client[bucket].keys.each do |key|
        Ripple.client[bucket][key].delete rescue nil
      end

      # paginations that are not prefixed for some reason
      paginations = [
        'audit_entries_paginated',
        'users_paginated',
        'developers_paginated',
        'applications_paginated']
      paginations.each do |bucket|
        Ripple.client[bucket].keys.each do |key|
          Ripple.client[bucket][key].delete rescue nil
        end
      end
    end
  end
end