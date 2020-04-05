# encoding: utf-8
module CarrierWave
  module Workers
    class ProcessAsset < Base
      def perform(*args)
        record = super(*args)

        return unless record || record.send(:"#{column}").present?

        record.send(:"process_#{column}_upload=", true)

        return unless record.send(:"#{column}").recreate_versions! || record.respond_to?(:"#{column}_processing")

        record.update_attribute :"#{column}_processing", false
      end
    end # ProcessAsset
  end # Workers
end # Backgrounder
