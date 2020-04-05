namespace :tips do
  desc 'Updated cached votes'
  task update_cached_votes: :environment do
    Domain.find_each do |domain|
      tenant_name = domain.tenant_name
      Rails.logger.info "====> tenant_name: #{tenant_name}"
      Apartment::Tenant.switch!(tenant_name)

      Rails.logger.info "====> Starting to update cached tip votes for domain: #{tenant_name}"

      Tip.find_each do |tip|
        tip.update_cached_votes(:like)
      end

      Rails.logger.info "====> Finished updating cached tip votes for domain: #{tenant_name}"
    end
  end

  desc 'Process all domain attachments as json in tip'
  task domain_attachments_to_json: :environment do
    PaperTrail.enabled = false

    Domain.all.each do |domain|
      Apartment::Tenant.switch domain.tenant_name do
        puts "====> Starting attachment json for domain: #{domain.tenant_name}"

        Tip.includes(:attachments).find_each(batch_size: 100) do |tip|
          begin
            tip.process_attachments_as_json
            Rails.logger.info "====> Finished JSON processing for tip ##{tip.id}"
          rescue
            next
          end
        end
      end

      Rails.logger.info "====> Finished processing JSON attachment for: #{domain.tenant_name}"
    end

    PaperTrail.enabled = true
  end

  desc 'Process public attachments as json in tip'
  task public_attachments_to_json: :environment do
    PaperTrail.enabled = false

    Apartment::Tenant.switch 'public' do
      puts '====> Starting attachment json for public.'

      Tip.includes(:attachments).find_each(batch_size: 100) do |tip|
        begin
          tip.process_attachments_as_json
          Rails.logger.info "====> Finished JSON processing for tip ##{tip.id}"
        rescue
          next
        end
      end
    end

    Rails.logger.info '====> Finished processing JSON attachment for public domain'

    PaperTrail.enabled = true
  end
end
