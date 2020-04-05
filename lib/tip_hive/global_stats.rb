module TipHive
  module GlobalStats
    class << self
      def stats
        domain_stats_list = all_domain_stats.sort_by { |stat| stat[:tippers_count] }.reverse!

        if $PROGRAM_NAME == 'rails_console'
          # rubocop:disable Rails/Output
          puts 'New Domain Totals'
          puts new_domain_totals

          # puts "\n Domain Stats"
          headers = {}.tap { |h| domain_stats_list.first.each { |k, _v| h[k] = k.to_s.humanize.titleize } }

          puts Hirb::Helpers::AutoTable.render(
            domain_stats_list,
            fields: domain_stats_list.first.keys,
            headers: headers
          )

          # rubocop:enable Rails/Output
        else
          {
            'data': {
              'stats': domain_stats_list,
              'new_domain_totals': new_domain_totals,
              'yearly_domain_counts': yearly_domain_counts
            }
          }.to_json
        end
      end

      def all_domain_stats
        domain_stats_list = []
        domain_list = Domain.where("tenant_name NOT ILIKE '%-th'")

        domain_list.each do |domain|
          Apartment::Tenant.switch domain.tenant_name do
            domain_stats = single_domain_stats_for(domain)

            next unless domain_stats

            domain_stats_list << domain_stats
          end
        end

        domain_stats_list
      end

      def single_domain_stats_for(domain)
        members = User.joins(:domain_memberships).where("domain_memberships.domain_id = #{domain.id}")
        members_count = members.size

        return false if members_count == 0

        total_tip_count = Tip.where("created_at >= '2016-03-01'").count
        total_comment_count = Comment.where("created_at >= '2016-03-01'").count
        total_likes_count = ActsAsVotable::Vote.where("created_at >= '2016-03-01'").where(vote_scope: 'like').count

        tippers_count = pro_tippers_count(domain, members)

        {
          domain: domain.tenant_name,
          tippers_count: tippers_count,
          members_count: members_count,
          tipper_percent: (tippers_count / members_count.to_f * 100).round(2),
          tip_count_this_week: tip_count_this_week,
          total_tip_count: total_tip_count,
          average_tip_count_per_week: average_tip_count(total_tip_count),
          total_comment_count: total_comment_count,
          total_likes_count: total_likes_count
        }
      end

      def pro_tippers_count(_domain, members)
        members.joins(:tips).select(:id).group('users.id').having('count(tips.id) > 10').to_a.size
      end

      def tip_count_this_week
        start_date = Time.now.in_time_zone('US/Eastern').beginning_of_week
        end_date = Time.now.in_time_zone('US/Eastern').end_of_week

        tips = Tip.select(:id).where("created_at BETWEEN '#{start_date}' AND '#{end_date}'")
        tips.count
      end

      def average_tip_count(total_tip_count)
        seconds = Time.now.in_time_zone('US/Eastern') - Time.parse('2016-03-01').in_time_zone('US/Eastern')
        days = seconds / (60 * 60 * 24)
        weeks = days / 7

        # weeks = (DateTime.now.in_time_zone('US/Eastern') - Date.new(2016, 3, 1).in_time_zone('US/Eastern')).to_i / 7.0
        return 0 if weeks <= 0

        average = total_tip_count / weeks
        average = average.round(2) if average < 1
        average = average.round if average >= 0

        average <= 0 ? '< 0' : average
      end

      def new_domain_totals
        # domain_list = Domain.where("tenant_name NOT ILIKE '%-th'")
        sql = 'select EXTRACT(YEAR FROM created_at) as year, EXTRACT(MONTH FROM created_at) as month, count(*)'
        sql += " from public.domains where tenant_name NOT ILIKE '%-th' group by year, month order by year, month;"

        results = ActiveRecord::Base.connection.execute sql

        results.values.map { |value| { 'year': value[0].to_i, 'month': value[1].to_i, 'count': value[2].to_i } }
      end

      def yearly_domain_counts
        years = [2015, 2016, 2017]

        domain_counts = {}
        years.each do |year|
          domain_counts[year] = domain_count_for(year)
        end

        domain_counts
      end

      def domain_count_for(year)
        from_date = "#{year}-01-01"

        from_date = '1970-01-01' if (year == 2015)

        to_date = "#{year}-12-31"

        Domain.where(created_at: (from_date..to_date)).where("tenant_name NOT ILIKE '%-th'").count
      end
    end
  end
end
