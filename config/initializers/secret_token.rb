# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
ROCCIServer::Application.config.secret_key_base = '4df309da2fac6c738fcc1e46a510607d7d43cbc43b438c1274f497ccfbfda2a9791a4beb48451b128afab6c195deca7801f5059adac3c6aa1407bc9817589734'
