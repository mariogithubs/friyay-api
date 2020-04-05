# rubocop:disable Rails/Output
module SpamControl
  class Spammer
    attr_reader :user, :domains

    attr_accessor :marked

    def initialize(user)
      @user = user
      @domains = Domain.where(user_id: user.id)
    end

    def mark
      self.marked = true
    end

    def unmark
      self.marked = false
    end

    def method_missing(method, *args)
      return unless user.attributes.keys.include?(method.to_s)

      if user.respond_to?(method)
        user.send(method, *args)
      else
        super
      end
    end

    def delete_domains
      domains.each do |domain|
        Apartment::Tenant.drop domain.tenant_name
        domain.destroy
      end
    end
  end

  class Spammers
    attr_reader :spammers

    def initialize(users)
      @spammers = create_spammers(users)
    end

    def reload
      @spammers = create_spammers(User.where(id: spammers.map(&:id)))
    end

    def list(scope = nil)
      puts Hirb::Helpers::AutoTable.render(
        spammer_table(scope),
        fields: [:marked, :user_id, :email, :domains, :created, :ip]
      )
    end

    def list_csv(scope = nil)
      puts spammer_table(scope).map { |s| s.values[1..100].join(',') }
    end

    def mark(range)
      spammers = find(range)

      spammers.each(&:mark)
    end

    def unmark(range)
      spammers = find(range)

      spammers.each(&:unmark)
    end

    def marked
      spammers.select { |spammer| spammer.marked == true }
    end

    def find(range)
      range = range.to_a if range.is_a?(Range)
      range = [range] unless range.is_a?(Array)

      spammers.select { |spammer| range.include?(spammer.id) }
    end

    def delete(spammer_id)
      # Just remove spammers from the list
      spammers.delete_if { |spammer| spammer.id == spammer_id }
    end

    def destroy_marked_domains!(password = nil)
      return unless password == ENV['ADMIN_SECRET']

      # DANGER: This will destroy domains
      marked.each do |spammer|
        spammer.domains.each do |domain|
          Apartment::Tenant.drop domain.tenant_name
          domain.destroy
          puts 'Domain Destroyed'
        end
      end

      spammers.reload
    end

    def destroy_marked_spammers!(password = nil)
      return unless password == ENV['ADMIN_SECRET']

      # DANGER: This will destroy users
      marked.each do |spammer|
        spammer.user.destroy
        puts 'Destroyed'
      end
    end

    private

    def create_spammers(users)
      users.map { |user| Spammer.new(user) }
    end

    def spammer_table(scope)
      spammer_list = scope.to_s == 'marked' ? marked : spammers

      spammer_list.sort_by(&:user_id).map do |spammer|
        { marked: spammer.marked ? 'X' : '',
          user_id: spammer.id,
          email: spammer.email,
          domains: build_domains_string(spammer.domains),
          created: spammer.created_at,
          ip: spammer.current_sign_in_ip
        }
      end
    end

    def build_domains_string(domains)
      return ',' if domains.blank?
      string_array = []

      domains.each do |domain|
        Apartment::Tenant.switch domain.tenant_name do
          string_array << "#{domain.id}: #{domain.tenant_name}, #{Invitation.count}"
        end
      end

      string_array.join("\n")
    end
  end
end
# rubocop:enable Rails/Output
