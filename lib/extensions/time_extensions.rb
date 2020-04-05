class Time
  def on_weekend?
    saturday? || sunday?
  end

  def on_weekday?
    !on_weekend?
  end
end
