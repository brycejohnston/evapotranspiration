require 'evapotranspiration/validation'
require 'evapotranspiration/fao'

module Evapotranspiration

  # Calculate potential evapotranspiration using the Thornthwaite (1948 method)
  #
  # References
  # ----------
  # Thornthwaite CW (1948) An approach toward a rational classification of
  # climate. Geographical Review, 38, 55-94.
  module Thornthwaite

    MONTHDAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    LEAP_MONTHDAYS = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    # Estimate monthly potential evapotranspiration (PET) using the
    # Thornthwaite (1948) method.
    #
    # Thornthwaite equation:
    #
    #  *PET* = 1.6 (*l*/12) (*n*/30) (10*ta* / *heat_index*)***a*
    #
    # where:
    #
    #  * *ta* is the mean daily air temperature [deg C, if negative use 0] of the
    #    month being calculated
    #  * *n* is the number of days in the month being calculated
    #  * *l* is the mean day length [hours] of the month being calculated
    #  * *a* = (6.75 x 10-7)*heat_index***3 - (7.71 x 10-5)*heat_index***2 + (1.792 x 10-2)*heat_index* + 0.49239
    #  * *heat_index* is a heat index which depends on the 12 monthly mean temperatures and
    #    is calculated as the sum of (*tai* / 5)**1.514 for each month, where
    #  * *tai* is the air temperature for each month in the year
    #
    # @param monthly_t [Array<Float>] Iterable containing mean daily air
    #   temperature for each month of the year (deg C)
    # @param monthly_mean_dlh [Array<Float>] Iterable containing mean daily
    #   daylight hours for each month of the year (hours). These can be
    #   calculated using monthly_mean_daylight_hours()
    # @param year [Integer] Year for which PET is required. The only effect of
    #   year is to change the number of days in February to 29 if it is a leap
    #   year. If it is left as the default (None), then the year is assumed not
    #   to be a leap year.
    # @return [Array<Float>] Estimated monthly potential evaporation of each month of
    #   the year (mm/month)
    def thornthwaite(monthly_t, monthly_mean_dlh, year=nil)
      if monthly_t.size != 12
        raise ArgumentError.new("monthly_t should be length 12 but is length #{monthly_t.size}.")
      end
      if monthly_mean_dlh.size != 12
        raise ArgumentError.new("monthly_mean_dlh should be length 12 but is length #{monthly_mean_dlh.size}.")
      end

      if year.nil? || !year.leap?
        month_days = MONTHDAYS
      else
        month_days = LEAP_MONTHDAYS
      end

      # Negative temperatures should be set to zero
      adj_monthly_t = []
      monthly_t.each do |t|
        adj_monthly_t << (t >= 0 ? t : 0)
      end

      # Calculate the heat index (heat_index)
      heat_index = 0.0
      adj_monthly_t.each do |tai|
        if (tai / 5.0) > 0.0
          heat_index += (tai / 5.0) ** 1.514
        end
      end

      a = (6.75e-07 * heat_index ** 3) - (7.71e-05 * heat_index ** 2) + (1.792e-02 * heat_index) + 0.49239

      pet = []
      adj_monthly_t.zip(monthly_mean_dlh, month_days).each do |ta, l, n|
        # Multiply by 10 to convert cm/month --> mm/month
        pet << 1.6 * (l / 12.0) * (n / 30.0) * ((10.0 * ta / heat_index) ** a) * 10.0
      end
      return pet
    end

    # Calculate mean daylight hours for each month of the year for a given
    # latitude.
    #
    # @param latitude [Float] Latitude (radians)
    # @param year [Integer] Year for the daylight hours are required. The only effect of
    #   *year* is to change the number of days in Feb to 29 if it is a leap
    #   year. If left as the default, None, then a normal (non-leap) year is
    #   assumed.
    # @return [Array<Float>] Mean daily daylight hours of each month of a year
    #   (hours)
    def monthly_mean_daylight_hours(latitude, year=nil)
      Validation.check_latitude_rad(latitude)

      if year.nil? || !year.leap?
        month_days = MONTHDAYS
      else
        month_days = LEAP_MONTHDAYS
      end
      monthly_mean_dlh = []
      doy = 1 # Day of the year

      month_days.each do |mdays|
        dlh = 0.0  # Cumulative daylight hours for the month
        [1..(mdays + 1)].each do |daynum|
          sd = FAO.sol_dec(doy)
          sha = FAO.sunset_hour_angle(latitude, sd)
          dlh += FAO.daylight_hours(sha)
          doy += 1
        end
        # Calc mean daylight hours of the month
        monthly_mean_dlh << (dlh / mdays)
      end

      return monthly_mean_dlh
    end

  end

end
