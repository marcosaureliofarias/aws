class AddCommunityOauth < EasyExtensions::EasyDataMigration
  def up
    EasyOauthClient.create(name:       'internal',
                           app_id:     'GBQTgDv3ytAuLysUQ2D5bYD6eZagMGZO3c5HwFBm',
                           app_secret: 'A1bdJDEQRNsX5SiVUUAKGh07koK2tdG63jx0jvMx') unless EasyOauthClient.where(name: 'internal').exists?
  end

  def down
  end
end
