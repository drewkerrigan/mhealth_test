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
    weight=$[ ( $RANDOM % 200 )  + 100 ]
    ts=$(date +"%Y%m%d%H%M")
    current_data='[{"name":"Weight","value":"WEIGHT","unit":"lb","timestamp":"TIMESTAMP"}]'
    current_data=${current_data/$weightconstant/$weight}
    current_data=${current_data/$timestampconstant/$ts}
    current_result="$current_data"
    current_path="APIHOSTv2/health/source/foobar_app/data?oauth_token=AUTHTOKEN" ; post
}

function readmeasure() {
    current_path="APIHOSTv2/health/data/mass?accept=jsonp&oauth_token=AUTHTOKEN" ; get
}

function op_all() {
    login
    dashboard
    settings
    writemeasure
    readmeasure
}

function op_login() {
    login
}

function op_nonstandardlogin() {
    login
    settings
    dashboard
}

function op_loginreadwrite() {
    login
    dashboard
    writemeasure
    readmeasure
}