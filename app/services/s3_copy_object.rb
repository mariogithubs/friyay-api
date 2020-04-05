class S3CopyObject
  def initialize(old_tenant_name, new_tenant_name)
    @base_path = "s3://#{ENV['FOG_AWS_BUCKET']}"
    @old_path = @base_path + "/storage/#{old_tenant_name}"
    @new_path = @base_path + "/storage/#{new_tenant_name}"
  end

  def copy_background_images(ids = nil)
    @from_prefix = @old_path + '/background_images'
    @to_prefix = @new_path + '/background_images'

    copy(ids)
  end

  def copy_documents(ids = nil)
    @from_prefix = @old_path + '/documents'
    @to_prefix = @new_path + '/documents'

    copy(ids)
  end

  def copy_images(ids = nil)
    @from_prefix = @old_path + '/images'
    @to_prefix = @new_path + '/images'

    copy(ids)
  end

  def delete_background_images(tenant_name)
    # puts "aws s3 rm s3://#{ENV['FOG_AWS_BUCKET']}/storage/#{tenant_name}/background_images --recursive"
    system "aws s3 rm s3://#{ENV['FOG_AWS_BUCKET']}/storage/#{tenant_name}/background_images --recursive"
  end

  def delete_documents(tenant_name)
    # puts "aws s3 rm s3://#{ENV['FOG_AWS_BUCKET']}/storage/#{tenant_name}/documents --recursive"
    system "aws s3 rm s3://#{ENV['FOG_AWS_BUCKET']}/storage/#{tenant_name}/documents --recursive"
  end

  def delete_images(tenant_name)
    # puts "aws s3 rm s3://#{ENV['FOG_AWS_BUCKET']}/storage/#{tenant_name}/images --recursive"
    system "aws s3 rm s3://#{ENV['FOG_AWS_BUCKET']}/storage/#{tenant_name}/images --recursive"
  end

  private

  def copy(ids)
    copy_directory(@from_prefix, @to_prefix) && return if ids.nil?

    copy_individual_assets(ids)
  end

  def copy_individual_assets(ids)
    ids = [ids] unless ids.is_a?(Array)

    ids.each do |id|
      from_prefix = @from_prefix + "/file/#{id}"
      to_prefix = @to_prefix + "/file/#{id}"

      copy_directory(from_prefix, to_prefix)
    end
  end

  def copy_directory(from_prefix, to_prefix)
    complete_from_path = @old_path + from_prefix
    complete_to_path = @new_path + to_prefix
    # puts "#{complete_from_path} #{complete_to_path}"

    system "aws s3 sync #{complete_from_path} #{complete_to_path}"
  end
end
