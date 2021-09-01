class IssueEasyDurationController < ApplicationController

  before_action :parse_dates, only: [:calculate_easy_duration, :move_date]

  def calculate_easy_duration
    if @start_date && @due_date
      easy_duration = IssueEasyDuration.easy_duration_calculate(@start_date, @due_date)
    end

    respond_to do |format|
      format.json { render json: easy_duration }
    end
  end

  def move_date
    if params[:easy_duration].present?
      date = IssueEasyDuration.move_date(params[:easy_duration], params[:easy_duration_unit], @start_date, @due_date)
    end

    respond_to do |format|
      format.json { render json: date }
    end
  end

  private

  def parse_dates
    @start_date = Date.safe_parse(params[:start_date])
    @due_date = Date.safe_parse(params[:due_date])
  end

end
