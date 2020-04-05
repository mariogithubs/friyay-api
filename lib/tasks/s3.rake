namespace :domains do
  desc 'Move all attachments'
  task move_attachments: :environment do
    printf 'What is the old tenant_name? '
    old_tenant_name = STDIN.gets.chomp

    next if old_tenant_name.blank?

    printf 'What is the new tenant_name (leave blank if same)? '
    new_tenant_name = STDIN.gets.chomp

    new_tenant_name = old_tenant_name if new_tenant_name.blank?

    puts "AWS SYNC s3://#{ENV['FOG_AWS_BUCKET']}/#{old_tenant_name}/ TO s3://#{ENV['FOG_AWS_BUCKET']}/#{new_tenant_name}/"
    printf "Do you want to move ALL attachments from #{old_tenant_name} to #{new_tenant_name}? "
    answer = STDIN.gets.chomp

    if ['no','n'].include?(answer)
      printf "What are the Tip IDs whose attachments you want to copy? "
      tip_ids = STDIN.gets.chomp.split(',').map(&:strip).map(&:to_i)
    else
      tip_ids = nil
    end

    s3 = S3CopyObject.new(old_tenant_name, new_tenant_name)

    s3.copy_documents(tip_ids)
    s3.copy_images(tip_ids)
  end

  # TODO: Make rask for copying background_images

  desc 'Delete all old attachments'
  task delete_attachments: :environment do
    printf 'Which tenant_name do you want to delete all attachments? '
    tenant_name = STDIN.gets.chomp

    next if tenant_name.blank?

    printf "Are you sure you want to DELETE ALL ATTACHMENTS from #{tenant_name}? "
    answer = STDIN.gets.chomp

    next unless ['yes','y'].include?(answer)

    delete_background_images(tenant_name)
    delete_documents(tenant_name)
    delete_images(tenant_name)
  end
end