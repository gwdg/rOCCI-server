# This is an EXAMPLE manifest to configure rOCCI-server.
# Do not use as-is. Modify setting according to your environment.

# puppet module install puppetlabs-apache

class { 'apache':
  default_mods        => false,
  default_confd_files => false,

  default_charset     => 'utf-8',
  server_signature    => false,
  server_tokens       => 'full',
  trace_enable        => 'On',
}

class { 'apache::mod::ssl':
  ssl_compression      => false,
  ssl_cipher           => 'kEECDH+AESGCM:kEECDH:HIGH:MEDIUM:!aNULL:!MD5:!RC4:!eNULL',
  ssl_honorcipherorder => 'on',
  ssl_protocol         => ['All', '-SSLv2', '-SSLv3'],
}

class { 'apache::mod::passenger': }
class { 'apache::mod::security': }
apache::mod { 'env': }

apache::vhost { 'occi-ssl':
  servername              => $::fqdn,
  port                    => 11443,
  docroot                 => '/opt/rOCCI-server/public',

  ssl                     => true,
  ssl_certs_dir           => '/etc/grid-security/certificates',
  ssl_cert                => '/etc/grid-security/hostcert.pem',
  ssl_key                 => '/etc/grid-security/hostkey.pem',
  ssl_crl_path            => '/etc/grid-security/certificates',
  # for X.509 access with GridSite/VOMS set to 'require'
  ssl_verify_client       => 'optional',
  ssl_verify_depth        => 10,
  # enable passing of SSL variables to passenger. For GridSite/VOMS, enable also exporting certificate data
  ssl_options             => ['+StdEnvVars', '+ExportCertData'],

  log_level               => 'info',

  directories             => {
    path            => '/opt/rOCCI-server/public',
    options         => ['-MultiViews'],
    custom_fragment => '
      #for GridSite/VOMS enable the four directives in the following block:
      #  ## variables (and is needed for gridsite-admin.cgi to work.)
      #  GridSiteEnvs on
      #  ## Nice GridSite directory listings (without truncating file names!)
      #  GridSiteIndexes off
      #  ## If this is greater than zero, we will accept GSI Proxies for clients,
      #  ## full client certificates - eg inside web browsers - are always ok
      #  GridSiteGSIProxyLimit 4
      #  ## This directive allows authorized people to write/delete files
      #  ## from non-browser clients - eg with htcp(1)
      #  GridSiteMethods ""
',
  },

  passenger_user          => 'rocci',
  passenger_min_instances => 3,

  setenv                  => [
    # configure OpenSSL inside rOCCI-server to validate peer certificates (for CMFs)
    #'SSL_CERT_FILE /path/to/ca_bundle.crt',
    #'SSL_CERT_DIR  /etc/grid-security/certificates',

    'ROCCI_SERVER_LOG_DIR /var/log/rocci-server',
    'ROCCI_SERVER_ETC_DIR /etc/rocci-server',

    'ROCCI_SERVER_PROTOCOL              https',
    "ROCCI_SERVER_HOSTNAME              ${::fqdn}",
    'ROCCI_SERVER_PORT                  11443',
    'ROCCI_SERVER_AUTHN_STRATEGIES      "voms x509 basic"',
    'ROCCI_SERVER_HOOKS                 dummy',

    'ROCCI_SERVER_BACKEND               dummy',
    #'ROCCI_SERVER_COMPUTE_BACKEND      dummy',
    #'ROCCI_SERVER_STORAGE_BACKEND      dummy',
    #'ROCCI_SERVER_NETWORK_BACKEND      dummy',

    'ROCCI_SERVER_LOG_LEVEL             info',
    'ROCCI_SERVER_LOG_REQUESTS_IN_DEBUG no',
    'ROCCI_SERVER_TMP                   /tmp/rocci_server',
    'ROCCI_SERVER_MEMCACHES             localhost:11211',
    'ROCCI_SERVER_ALLOW_EXPERIMENTAL_MIMES no',

    # authn
    'ROCCI_SERVER_AUTHN_VOMS_ROBOT_SUBPROXY_IDENTITY_ENABLE   no',
    #'ROCCI_SERVER_USER_BLACKLIST_HOOK_USER_BLACKLIST          "/path/to/yml/file.yml"',
    #'ROCCI_SERVER_USER_BLACKLIST_HOOK_FILTERED_STRATEGIES     "voms x509 basic"',
    #'ROCCI_SERVER_ONEUSER_AUTOCREATE_HOOK_VO_NAMES            "dteam ops"',

    # ONE backend
    'ROCCI_SERVER_ONE_XMLRPC  http://localhost:2633/RPC2',
    'ROCCI_SERVER_ONE_USER    rocci',
    'ROCCI_SERVER_ONE_PASSWD  yourincrediblylonganddifficulttoguesspassword',
    #'ROCCI_SERVER_ONE_STORAGE_DATASTORE_ID 1',

    ## EC2 backend
    'ROCCI_SERVER_EC2_AWS_ACCESS_KEY_ID          myec2accesskeyid',
    'ROCCI_SERVER_EC2_AWS_SECRET_ACCESS_KEY      yourincrediblylonganddifficulttoguesspassword',
    'ROCCI_SERVER_EC2_AWS_REGION                 eu-west-1',
    # Do NOT change this value unless you know exactly what you are doing!
    # Endpoint must be a valid URL starting with http:// or https://
    #'ROCCI_SERVER_EC2_AWS_ENDPOINT               ""',
    'ROCCI_SERVER_EC2_AWS_AVAILABILITY_ZONE      eu-west-1a',
    'ROCCI_SERVER_EC2_IMAGE_FILTERING_POLICY     only_listed',
    'ROCCI_SERVER_EC2_IMAGE_FILTERING_IMAGE_LIST "ami-8b8c57f8 ami-f4278487 ami-f95ef58a"',
    'ROCCI_SERVER_EC2_NETWORK_CREATE_ALLOWED     no',
    'ROCCI_SERVER_EC2_NETWORK_DESTROY_ALLOWED    no',
    'ROCCI_SERVER_EC2_NETWORK_DESTROY_VPN_GWS    no',
    'ROCCI_SERVER_EC2_VO_AWS_MAPFILE             ""',
  ],

  custom_fragment         => '
    PassengerFriendlyErrorPages off
    RackEnv production
',
}

apache::custom_config { 'occi-signature':
  content => 'SecServerSignature "Apache rOCCI-server OCCI/1.1"',
}
