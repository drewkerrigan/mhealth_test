TIMEFORMAT=%R

current_email=""
current_uid=""
current_name=""
current_authtoken=""

current_result=""
current_path=""
current_data=""

function prepare() {
    current_path=${current_path/$emailconstant/$current_email}
    current_path=${current_path/$uidconstant/$current_uid}
    current_path=${current_path/$nameconstant/$current_name}
    current_path=${current_path/$authtokenconstant/$current_authtoken}
    current_path=${current_path/$namespaceconstant/$namespace}
    current_path=${current_path/$riakhostconstant/$riakhost}
    current_path=${current_path/$apihostconstant/$apihost}
}

function put() {
    prepare
    current_result=`curl -k -s -H "Content-Type: application/json" -XPUT $current_path -d "$current_result"`
}

function get() {
    prepare
    current_result=`curl -k -s -H "Content-Type: application/json" -XGET $current_path`
}

function post() {
    prepare
    current_result=`curl -k -s -H "Content-Type: application/json" -XPOST $current_path -d "$current_result"`
}

function custom_data() {
    current_path="$current_data"
    prepare
    current_result="$current_path"
}

function riak_stats() {
    current_path="RIAKHOSTstats" ; get
    echo $current_result >> $results_dir/riak_stats.txt
}

function riak_keycounts() {
    with_header=$1
    counta=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"m_health_models_daily_logs');"`
    countb=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"m_health_models_users');"`
    countc=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('audit_entries_paginated');"`
    countd=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('users_paginated');"`
    counte=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"m_health_models_product_lists');"`
    countf=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"m_health_models_products');"`
    countg=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"authorization_codes');"`
    counth=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"users');"`
    counti=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"audit_entries');"`
    countj=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"applications');"`
    countk=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('developers_paginated');"`
    countl=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"developers');"`
    countm=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"m_health_models_applications');"`
    countn=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"global_settings');"`
    counto=`node -e "require('riak-js').getClient({ host: '$riakbase', port: $riakport }).count('"$namespace"applications_paginated');"`

    if [ "$with_header" == TRUE ]
    then 
    echo "psra_m_health_models_daily_logs,psra_m_health_models_users,audit_entries_paginated,users_paginated,psra_m_health_models_product_lists,psra_m_health_models_products,psra_authorization_codes,psra_users,psra_audit_entries,psra_applications,developers_paginated,psra_developers,psra_m_health_models_applications,psra_global_settings,applications_paginated" >> $results_dir/riak_key_counts.txt    
    fi

    echo "$counta,$countb,$countc,$countd,$counte,$countf,$countg,$counth,$counti,$countj,$countk,$countl,$countm,$countn,$counto" >> $results_dir/riak_key_counts.txt
}

function login() {
    current_path="RIAKHOSTbuckets/NAMESPACEusers/index/email_bin/USEREMAIL" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEusers/keys/USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEusers/keys/USERID?returnbody=true" ; put
    current_path="RIAKHOSTbuckets/NAMESPACEusers/keys/USERID?returnbody=true" ; put

    current_path="APIHOSTv2/health/internal/user/USERID" ; get
    current_data='{"name":"FULLNAME","email":"USEREMAIL","phone_numbers":[],"timezone":"GMT-8:00"}' ; custom_data
    current_path="APIHOSTv2/health/internal/user/USERID" ; put
    current_data='{"name":"FULLNAME","email":"USEREMAIL","phone_numbers":[],"timezone":"GMT-8:00"}' ; custom_data
    current_path="APIHOSTv2/health/internal/user/USERID" ; put
}

function dashboard() {
    current_path="RIAKHOSTbuckets/NAMESPACEconnections/keys/myzeo-USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEconnections/keys/fitbit-USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEconnections/keys/withings-USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEdevelopers/keys/USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEusers/keys/USERID" ; get
    current_path="APIHOSTv2/health/data?all_measures=true&oauth_token=AUTHTOKEN" ; get
    current_path="APIHOSTv2/health/user?oauth_token=AUTHTOKEN" ; get
}

function settings() {
    current_path="RIAKHOSTbuckets/NAMESPACEusers/keys/USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEusers/keys/USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEmobile_requests/index/user_id_bin/USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEemail_requests/index/user_id_bin/USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEdevelopers/keys/USERID" ; get
    current_path="RIAKHOSTbuckets/NAMESPACEusers/keys/USERID" ; get
}

function writemeasure() {
    for (( i=1; i <= $mwrites; i++ ))
    do
        weight=$[ ( $RANDOM % 200 )  + 100 ]
        ts=$(date --date="10 days ago" +"%Y%m%d%H%M")
        current_data='[{"name":"Weight","value":"WEIGHT","unit":"lb","timestamp":"TIMESTAMP"}]'
        current_data=${current_data/$weightconstant/$weight}
        current_data=${current_data/$timestampconstant/$ts}
        current_result="$current_data"
        current_path="APIHOSTv2/health/source/foobar_app/data?oauth_token=AUTHTOKEN" ; post
    done
}

function readmeasure() {
    for (( i=1; i <= $mreads; i++ ))
    do
        current_path="APIHOSTv2/health/data/mass?accept=jsonp&oauth_token=AUTHTOKEN" ; get
    done
}

function header() {
    header="worker,elapsed,session,$ops"
    echo $header >> $results_dir/stats.txt
}

function op_run() {
    total=0
    list=""

    for operation in login dashboard settings writemeasure readmeasure
    do
        if [[ "$ops" == *$operation* ]]
        then 
            op_t=$( { time $operation > /dev/null; } 2>&1 )
            list=$list",$op_t"
            total=`echo $total+$op_t | bc`
        fi
    done

    ts=$((nowtime - starttime))
    echo "$WORKERID,$ts,$total$list" >> $results_dir/stats.txt
}