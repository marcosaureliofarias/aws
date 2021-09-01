class EasyRakeTaskEasyQuerySnapshot < EasyRakeTask

  def execute
    EasyQuerySnapshot.run_now.find_each(batch_size: 1) do |easy_query_snapshot|
      nextrun_at = EasyUtils::DateUtils.calculate_from_period_options(Date.today, easy_query_snapshot.period_options)
      easy_query_snapshot.update_columns(nextrun_at: nextrun_at)

      compute_data(easy_query_snapshot)

      easy_query_snapshot.update_columns(last_executed: Time.now)
    end

    true
  end

  def compute_data(easy_query_snapshot)
    easy_query_snapshot.executable_user.execute do
      query = easy_query_snapshot.create_easy_query

      if query
        data = easy_query_snapshot.easy_query_snapshot_data.build(date: Date.today)

        query.inline_columns.select(&:sumable_header?).first(5).each_with_index do |column, idx|
          data.send(:"value#{idx + 1}=", query.entity_sum(column))
        end

        data.save
      end
    end
  end

end
