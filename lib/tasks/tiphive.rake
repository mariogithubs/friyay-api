namespace :tiphive do
  desc 'Reindex all'
  task reindex: :environment do
    Rake::Task['tiphive:clear_all_indexes'].invoke
    Rake::Task['tiphive:reindex_public'].invoke
    Rake::Task['tiphive:reindex_domains'].invoke
  end

  desc 'Clear ALL indexes'
  task clear_all_indexes: :environment do
    puts '====> Clearing all indexes...'
    public_models = [User, DomainMember, Topic, Tip, Group]
    public_models.each(&:solr_remove_all_from_index!)
  end

  desc 'Reindex public'
  task reindex_public: :environment do
    puts '====> Reindexing public models...'
    public_models = [Topic, Tip, User, Group]

    puts "====> Reindexing #{public_models.map(&:name)}"


    public_models.each do |model|
      puts "====> Reindexing #{model.name}"
      puts "====> #{model.name}.count: #{model.count}"
      model.find_in_batches(batch_size: 1000) do |models|
        puts "===> Reindexing batch of #{models.count} #{model.name}"
        Sunspot.index! models
      end
    end
  end

  desc 'Reindex domains'
  task reindex_domains: :environment do
    domain_models = [Topic, Tip, Group]
    puts '====> Reindexing domain models...'

    Domain.find_each do |domain|
      tenant_name = domain.tenant_name

      Apartment::Tenant.switch tenant_name do
        puts "====> Starting to index for domain: #{tenant_name}"

        domain_models.each do |model|
          puts "====> tenant_name: #{Apartment::Tenant.current} - reindexing #{model.name}"
          puts "====> #{model.name}.count: #{model.count}"
          model.find_in_batches(batch_size: 1000) do |models|
            puts "===> Reindexing batch of #{models.count} #{model.name}"
            Sunspot.index! models
          end
        end

        domain.users.find_in_batches(batch_size: 1000) do |members|
          Sunspot.index! members
        end

        puts "====> Finished indexing for domain: #{tenant_name}"
      end
    end
  end

  # def public_models
  #   default_models = [Topic, Tip, User, Group] #Question

  #   return default_models unless ENV['models']

  #   requested_models = ENV['models'].split(",").map(&:constantize)
  #   return requested_models if (requested_models - default_models).empty?

  #   default_models
  # end

  # def domain_models
  #   default_models = [Topic, Tip, Group] #Question

  #   return default_models unless ENV['models']

  #   requested_models = ENV['models'].split(",").map(&:constantize)
  #   return requested_models if (requested_models - default_models).empty?

  #   default_models
  # end
end
