Time::DATE_FORMATS.merge!(
  month_and_day_with_ordinal: lambda { |dt| dt.strftime("%B #{dt.day.ordinalize}") }
)
