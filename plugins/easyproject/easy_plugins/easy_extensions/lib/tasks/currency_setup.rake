namespace :easyproject do
  desc <<-END_DESC
    Currencies initializations and recalculation of historical entities

    Example:
      bundle exec rake easyproject:currency_update_tables_and_recalculate RAILS_ENV=production
      bundle exec rake easyproject:currency_update_tables RAILS_ENV=production
      bundle exec rake easyproject:currency_recalculate_all RAILS_ENV=production
      bundle exec rake easyproject:migrate_currency_setting RAILS_ENV=production
      bundle exec rake easyproject:initialize_currency_from_projects RAILS_ENV=production
  END_DESC

  task :currency_update_tables => :environment do
    initialize_tables
    setting       = EasySetting.find_or_initialize_by(name: 'easy_currencies_initialized', project_id: nil)
    setting.value = true
    setting.save
    puts 'Please restart server to activate new currencies.'
  end

  task :initialize_currency_from_projects => :environment do
    EasyInvoice.where(easy_currency_code: nil).includes(:project).each do |invoice|
      code = invoice.project.self_and_ancestors.where.not(easy_currency_code: nil).order(:lft => :desc).pluck(:easy_currency_code).first
      invoice.update_columns(easy_currency_code: code)
    end
    true
  end

  task :currency_update_tables_and_recalculate => :environment do
    changed_models = initialize_tables
    recalculate_values(changed_models.map { |x| x[:model] })
    setting       = EasySetting.find_or_initialize_by(name: 'easy_currencies_initialized', project_id: nil)
    setting.value = true
    setting.save
    true
    puts 'Please restart server to activate new currencies.'
  end

  task :migrate_currency_setting => :environment do
    currency_code_list = nil
    File.open(EasyCurrency::ISO_PATH) do |file|
      currency_code_list = Hash.from_xml(file)["ISO_4217"]["CcyTbl"]["CcyNtry"].reject { |x| x["Ccy"].nil? }.uniq.map { |x| x['Ccy'] }
    end
    #host_name = Setting.where(name: :host_name).first.value
    invocing_setting = Hash[EasySetting.where(name: :easy_invoicing_default_currency).pluck(:project_id, :value)]
    Project.all.each do |project|
      invocing_currency = invocing_setting[project.id] || invocing_setting[nil]
      if currency_code_list.include?(invocing_currency)
        project.update_column(:easy_currency_code, invocing_currency)
        Rails.logger.info "Project #{project.name} # #{project.id} set to #{invocing_currency}"
        puts "Project #{project.name} # #{project.id} set to #{invocing_currency}"
      else
        # puts "Manual change needed project #{project.name} # #{settings_project_url(project, host: host_name)} has invalid currency #{invocing_currency}"
      end
    end
  end

  task :currency_recalculate_all => :environment do
    recalculate_values(EasyEntityWithCurrency.entities)
  end

  def recalculate_values(models) # SLOOOOOOOOW
    models.each do |model|
      puts "Recalculating #{model} price columns"
      model.find_each(batch_size: 100) do |entity|
        entity.update_columns(entity.recalculate_prices_in_currencies)
      end
    end
  end

  def initialize_tables(drop = nil)
    EasyCurrency.reinitialize_tables(drop)
  end

end
