require 'easy_extensions/spec_helper'

describe 'Installation process', slow: true, installation: true do

  describe 'migrations from pure redmine' do
    # before(:all) do
    #   @db_name = ActiveRecord::Base.connection.current_database + '_migrations'
    #   ActiveRecord::Base.connection.execute('CREATE DATABASE ' + @db_name + ';')
    #   ActiveRecord::Base.establish_connection( ActiveRecord::Base.connection.connection_parameters.merge(dbname: @db_name) )
    #   ActiveRecord::Migrator.migrate
    # end

    # after(:all) do
    #   ActiveRecord::Base.connection.execute('DROP DATABASE ' + @db_name + ';')
    # end

    # it 'should migrate from clean redmine' do
    #   expect { Redmine::Plugin.migrate }.not_to raise_error
    # end

  end

end
