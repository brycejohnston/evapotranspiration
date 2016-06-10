require 'evapotranspiration/validation'

module Evapotranspiration

  # Methods for estimating reference evapotransporation (ETo) for
  # a grass reference crop using the FAO-56 Penman-Monteith and Hargreaves
  # equations. The library includes numerous methods for estimating missing
  # meteorological data.
  module FAO
    include Enumerable

    # Solar constant [ MJ m-2 min-1]
    SOLAR_CONSTANT = 0.0820

    # Stefan Boltzmann constant [MJ K-4 m-2 day-1]
    STEFAN_BOLTZMANN_CONSTANT = 0.000000004903

    # Estimate atmospheric pressure from altitude.
    #
    # Calculated using a simplification of the ideal gas law, assuming 20 degrees
    # Celsius for a standard atmosphere. Based on equation 7, page 62 in Allen
    # et al (1998).
    #
    # @param altitude [Float] Elevation/altitude above sea level (m)
    # @return [Float] atmospheric pressure (kPa)
    def self.atm_pressure(altitude)
      tmp = (293.0 - (0.0065 * altitude.to_f)) / 293.0
      return (tmp.to_f ** 5.26) * 101.3
    end

    # Estimate actual vapour pressure (*ea*) from minimum temperature.
    #
    # This method is to be used where humidity data are lacking or are of
    # questionable quality. The method assumes that the dewpoint temperature
    # is approximately equal to the minimum temperature (*tmin*), i.e. the
    # air is saturated with water vapour at *tmin*.
    #
    # **Note**: This assumption may not hold in arid/semi-arid areas.
    # In these areas it may be better to subtract 2 deg C from the
    # minimum temperature (see Annex 6 in FAO paper).
    #
    # Based on equation 48 in Allen et al (1998).
    #
    # @param tmin [Float] Daily minimum temperature (deg C)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_tmin(tmin)
      return 0.611 * Math.exp((17.27 * tmin.to_f) / (tmin.to_f + 237.3))
    end

    # Estimate actual vapour pressure (*ea*) from saturation vapour pressure and
    # relative humidity.
    #
    # Based on FAO equation 17 in Allen et al (1998).
    #
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum
    #   temperature (kPa). Can be estimated using svp_from_t
    # @param svp_tmax [Float] Saturation vapour pressure at daily maximum
    #   temperature (kPa). Can be estimated using svp_from_t
    # @param rh_min [Float] Minimum relative humidity (%)
    # @param rh_max [Float] Maximum relative humidity (%)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmin_rhmax(svp_tmin, svp_tmax, rh_min, rh_max)
      tmp1 = svp_tmin.to_f * (rh_max.to_f / 100.0)
      tmp2 = svp_tmax.to_f * (rh_min.to_f / 100.0)
      return (tmp1.to_f + tmp2.to_f) / 2.0
    end

    # Estimate actual vapour pressure (*ea*) from saturation vapour pressure at
    # daily minimum and maximum temperature, and mean relative humidity.
    #
    # Based on FAO equation 19 in Allen et al (1998).
    #
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum
    #   temperature (kPa). Can be estimated using svp_from_t
    # @param rh_max [Float] Maximum relative humidity (%)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmax(svp_tmin, rh_max)
      return svp_tmin.to_f * (rh_max.to_f / 100.0)
    end

    # Estimate actual vapour pressure (*e*a) from saturation vapour pressure at
    # daily minimum temperature and maximum relative humidity.
    #
    # Based on FAO equation 18 in Allen et al (1998).
    #
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum
    #   temperature (kPa). Can be estimated using svp_from_t
    # @param svp_tmax [Float] Saturation vapour pressure at daily maximum
    #   temperature (kPa). Can be estimated using svp_from_t
    # @param rh_mean [Float] Mean relative humidity (%) (average of RH min and RH max).
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmean(svp_tmin, svp_tmax, rh_mean)
      return (rh_mean.to_f / 100.0) * ((svp_tmax.to_f + svp_tmin.to_f) / 2.0)
    end

    # Estimate actual vapour pressure (*ea*) from dewpoint temperature.
    #
    # Based on equation 14 in Allen et al (1998). As the dewpoint temperature is
    # the temperature to which air needs to be cooled to make it saturated, the
    # actual vapour pressure is the saturation vapour pressure at the dewpoint
    # temperature.
    #
    # This method is preferable to calculating vapour pressure from
    # minimum temperature.
    #
    # @param tdew [Float] Dewpoint temperature (deg C)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_tdew(tdew)
      return 0.6108 * Math.exp((17.27 * tdew.to_f) / (tdew.to_f + 237.3))
    end

    # Estimate actual vapour pressure (*ea*) from wet and dry bulb temperature.
    #
    # Based on equation 15 in Allen et al (1998). As the dewpoint temperature
    # is the temperature to which air needs to be cooled to make it saturated, the
    # actual vapour pressure is the saturation vapour pressure at the dewpoint
    # temperature.
    #
    # This method is preferable to calculating vapour pressure from
    # minimum temperature.
    #
    # Values for the psychrometric constant of the psychrometer (*psy_const*)
    # can be calculated using psyc_const_of_psychrometer.
    #
    # @param twet [Float] Wet bulb temperature (deg C)
    # @param tdry [Float] Dry bulb temperature (deg C)
    # @param svp_twet [Float] Saturated vapour pressure at the wet bulb
    #   temperature (kPa). Can be estimated using svp_from_t
    # @param psy_const [Float] Psychrometric constant of the pyschrometer
    #   (kPa deg C-1). Can be estimated using psy_const or
    #   psy_const_of_psychrometer
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_twet_tdry(twet, tdry, svp_twet, psy_const)
      return svp_twet.to_f - (psy_const.to_f * (tdry.to_f - twet.to_f))
    end

    # Estimate clear sky radiation from altitude and extraterrestrial radiation.
    #
    # Based on equation 37 in Allen et al (1998) which is recommended when
    # calibrated Angstrom values are not available.
    #
    # @param altitude [Float] Elevation above sea level (m)
    # @param et_rad [Float] Extraterrestrial radiation (MJ m-2 day-1). Can be
    #   estimated using et_rad
    # @return [Float] Clear sky radiation (MJ m-2 day-1)
    def self.cs_rad(altitude, et_rad)
      return (0.00002 * altitude.to_f + 0.75) * et_rad.to_f
    end

    # Estimate mean daily temperature from the daily minimum and maximum
    # temperatures.
    #
    # @param tmin [Float] Minimum daily temperature (deg C)
    # @param tmax [Float] Maximum daily temperature (deg C)
    # @return [Float] Mean daily temperature (deg C)
    def self.daily_mean_t(tmin, tmax)
      return (tmax.to_f + tmin.to_f) / 2.0
    end

    # Calculate daylight hours from sunset hour angle.
    #
    # Based on FAO equation 34 in Allen et al (1998).
    #
    # @param sha [Float] Sunset hour angle (rad). Can be calculated using
    #   sunset_hour_angle
    # @return [Float] Daylight hours
    def self.daylight_hours(sha)
      Validation.check_sunset_hour_angle_rad(sha)
      return (24.0 / Math::PI) * sha.to_f
    end

    # Estimate the slope of the saturation vapour pressure curve at a given
    # temperature.
    #
    # Based on equation 13 in Allen et al (1998). If using in the Penman-Monteith
    # *t* should be the mean air temperature.
    #
    # @param t [Float] Air temperature (deg C). Use mean air temperature for
    #   use in Penman-Monteith
    # @return [Float] Saturation vapour pressure (kPa degC-1)
    def self.delta_svp(t)
      tmp = 4098 * (0.6108 * Math.exp((17.27 * t.to_f) / (t.to_f + 237.3)))
      return tmp.to_f / ((t.to_f + 237.3) ** 2)
    end

    # Convert energy (e.g. radiation energy) in MJ m-2 day-1 to the equivalent
    # evaporation, assuming a grass reference crop.
    #
    # Energy is converted to equivalent evaporation using a conversion
    # factor equal to the inverse of the latent heat of vapourisation
    # (1 / lambda = 0.408).
    #
    # Based on FAO equation 20 in Allen et al (1998).
    #
    # @param energy [Float] Energy e.g. radiation or heat flux (MJ m-2 day-1)
    # @return [Float] Equivalent evaporation (mm day-1)
    def self.energy_to_evap(energy)
      return 0.408 * energy.to_f
    end

    # Estimate daily extraterrestrial radiation (*Ra*, 'top of the atmosphere
    # radiation').
    #
    # Based on equation 21 in Allen et al (1998). If monthly mean radiation is
    # required make sure *sol_dec*. *sha* and *irl* have been calculated using
    # the day of the year that corresponds to the middle of the month.
    #
    # **Note**: From Allen et al (1998): "For the winter months in latitudes
    # greater than 55 degrees (N or S), the equations have limited validity.
    # Reference should be made to the Smithsonian Tables to assess possible
    # deviations."
    #
    # @param latitude [Float] Latitude (radians)
    # @param sol_dec [Float] Solar declination (radians). Can be calculated
    #   using sol_dec
    # @param sha [Float] Sunset hour angle (radians). Can be calculated using
    #   sunset_hour_angle
    # @param ird [Float] Inverse relative distance earth-sun (dimensionless).
    #   Can be calculated using inv_rel_dist_earth_sun
    # @return [Float] Daily extraterrestrial radiation (MJ m-2 day-1)
    def self.et_rad(latitude, sol_dec, sha, ird)
      Validation.check_latitude_rad(latitude)
      Validation.check_sol_dec_rad(sol_dec)
      Validation.check_sunset_hour_angle_rad(sha)

      tmp1 = (24.0 * 60.0) / Math::PI
      tmp2 = sha.to_f * Math.sin(latitude) * Math.sin(sol_dec.to_f)
      tmp3 = Math.cos(latitude.to_f) * Math.cos(sol_dec.to_f) * Math.sin(sha.to_f)
      return tmp1.to_f * SOLAR_CONSTANT * ird.to_f * (tmp2.to_f + tmp3.to_f)
    end

    # Estimate reference evapotranspiration (ETo) from a hypothetical
    # short grass reference surface using the FAO-56 Penman-Monteith equation.
    #
    # Based on equation 6 in Allen et al (1998).
    #
    # @param net_rad [Float] Net radiation at crop surface (MJ m-2 day-1). If
    #   necessary this can be estimated using net_rad
    # @param t [Float] Air temperature at 2 m height (deg Kelvin)
    # @param ws [Float] Wind speed at 2 m height (m s-1). If not measured at 2m,
    #   convert using wind_speed_at_2m
    # @param svp [Float] Saturation vapour pressure (kPa). Can be estimated
    #   using svp_from_t
    # @param avp [Float] Actual vapour pressure (kPa). Can be estimated using a
    #   range of methods with names beginning with avp_from
    # @param delta_svp [Float] Slope of saturation vapour pressure curve
    #   (kPa degC-1). Can be estimated using delta_svp
    # @param psy [Float] Psychrometric constant (kPa deg C). Can be estimatred
    #   using psy_const_of_psychrometer or psy_const
    # @param shf [Float] Soil heat flux (G) (MJ m-2 day-1) (default is 0.0,
    #   which is reasonable for a daily or 10-day time steps). For monthly time
    #   steps *shf* can be estimated using monthly_soil_heat_flux or
    #   monthly_soil_heat_flux2
    # @return [Float] Reference evapotranspiration (ETo) from a hypothetical
    #   grass reference surface (mm day-1)
    def self.fao56_penman_monteith(net_rad, t, ws, svp, avp, delta_svp, psy, shf=0.0)
      a1 = (0.408 * (net_rad.to_f - shf.to_f) * delta_svp.to_f / (delta_svp.to_f + (psy.to_f * (1 + 0.34 * ws.to_f))))
      a2 = (900 * ws.to_f / t.to_f * (svp.to_f - avp.to_f) * psy.to_f / (delta_svp.to_f + (psy.to_f * (1 + 0.34 * ws.to_f))))
      return a1.to_f + a2.to_f
    end

    # Estimate reference evapotranspiration over grass (ETo) using the Hargreaves
    # equation.
    #
    # Generally, when solar radiation data, relative humidity data
    # and/or wind speed data are missing, it is better to estimate them using
    # the methods available in this module, and then calculate ETo
    # the FAO Penman-Monteith equation. However, as an alternative, ETo can be
    # estimated using the Hargreaves ETo equation.
    #
    # Based on equation 52 in Allen et al (1998).
    #
    # @param tmin [Float] Minimum daily temperature (deg C)
    # @param tmax [Float] Maximum daily temperature (deg C)
    # @param tmean [Float] Mean daily temperature (deg C). If measurements not
    #   available it can be estimated as (*tmin* + *tmax*) / 2
    # @param et_rad [Float] Extraterrestrial radiation (Ra) (MJ m-2 day-1).
    #   Can be estimated using et_rad
    # @return [Float] Reference evapotranspiration over grass (ETo) (mm day-1)
    def self.hargreaves(tmin, tmax, tmean, et_rad)
      # Note, multiplied by 0.408 to convert extraterrestrial radiation could
      # be given in MJ m-2 day-1 rather than as equivalent evaporation in
      # mm day-1
      return 0.0023 * (tmean.to_f + 17.8) * (tmax.to_f - tmin.to_f) ** 0.5 * 0.408 * et_rad.to_f
    end

    # Calculate the inverse relative distance between earth and sun from
    # day of the year.
    #
    # Based on FAO equation 23 in Allen et al (1998).
    #
    # @param day_of_year [Integer] Day of the year (1 to 366)
    # @return [Float] Inverse relative distance between earth and the sun
    def self.inv_rel_dist_earth_sun(day_of_year)
      Validation.check_doy(day_of_year)
      return 1 + (0.033 * Math.cos((2.0 * Math::PI / 365.0) * day_of_year.to_f))
    end

    # Estimate mean saturation vapour pressure, *es* [kPa] from minimum and
    # maximum temperature.
    #
    # Based on equations 11 and 12 in Allen et al (1998).
    #
    # Mean saturation vapour pressure is calculated as the mean of the
    # saturation vapour pressure at tmax (maximum temperature) and tmin
    # (minimum temperature).
    #
    # @param tmin [Float] Minimum temperature (deg C)
    # @param tmax [Float] Maximum temperature (deg C)
    # @return [Float] Mean saturation vapour pressure (*es*) (kPa)
    def self.mean_svp(tmin, tmax)
      return (self.svp_from_t(tmin.to_f) + self.svp_from_t(tmax.to_f)) / 2.0
    end

    # Estimate monthly soil heat flux (Gmonth) from the mean air temperature of
    # the previous and next month, assuming a grass crop.
    #
    # Based on equation 43 in Allen et al (1998). If the air temperature of the
    # next month is not known use monthly_soil_heat_flux2 instead. The
    # resulting heat flux can be converted to equivalent evaporation [mm day-1]
    # using energy_to_evap.
    #
    # @param t_month_prev [Float] Mean air temperature of the previous month
    #   (deg Celsius)
    # @param t_month_next [Float] Mean air temperature of the next month
    #   (deg Celsius)
    # @return [Float] Monthly soil heat flux (Gmonth) (MJ m-2 day-1)
    def self.monthly_soil_heat_flux(t_month_prev, t_month_next)
      return 0.07 * (t_month_next.to_f - t_month_prev.to_f)
    end

    # Estimate monthly soil heat flux (Gmonth) from the mean air temperature of
    # the previous and next month, assuming a grass crop.
    #
    # Based on equation 44 in Allen et al (1998). If the air temperature of the
    # next month is available, use monthly_soil_heat_flux instead. The
    # resulting heat flux can be converted to equivalent evaporation [mm day-1]
    # using energy_to_evap.
    #
    # @param t_month_prev [Float] Mean air temperature of the previous month
    #   (deg Celsius)
    # @param t_month_cur [Float] Mean air temperature of the current month
    #   (deg Celsius)
    # @return [Float] Monthly soil heat flux (Gmonth) (MJ m-2 day-1)
    def self.monthly_soil_heat_flux2(t_month_prev, t_month_cur)
      return 0.14 * (t_month_cur.to_f - t_month_prev.to_f)
    end

    # Calculate net incoming solar (or shortwave) radiation from gross
    # incoming solar radiation, assuming a grass reference crop.
    #
    # Net incoming solar radiation is the net shortwave radiation resulting
    # from the balance between incoming and reflected solar radiation. The
    # output can be converted to equivalent evaporation [mm day-1] using
    # energy_to_evap.
    #
    # Based on FAO equation 38 in Allen et al (1998).
    #
    # @param sol_rad [Float] Gross incoming solar radiation (MJ m-2 day-1).
    #   If necessary this can be estimated using methods whose name begins
    #   with sol_rad_from
    # @param albedo [Float] Albedo of the crop as the proportion of gross
    #   incoming solar radiation that is reflected by the surface. Default value
    #   is 0.23, which is the value used by the FAO for a short grass reference
    #   crop. Albedo can be as high as 0.95 for freshly fallen snow and as low
    #   as 0.05 for wet bare soil. A green vegetation over has an albedo of
    #   about 0.20-0.25 (Allen et al, 1998)
    # @return [Float] Net incoming solar (or shortwave) radiation (MJ m-2 day-1)
    def self.net_in_sol_rad(sol_rad, albedo=0.23)
      return (1 - albedo.to_f) * sol_rad.to_f
    end

    # Estimate net outgoing longwave radiation.
    #
    # This is the net longwave energy (net energy flux) leaving the
    # earth's surface. It is proportional to the absolute temperature of
    # the surface raised to the fourth power according to the Stefan-Boltzmann
    # law. However, water vapour, clouds, carbon dioxide and dust are absorbers
    # and emitters of longwave radiation. This method corrects the Stefan-
    # Boltzmann law for humidity (using actual vapor pressure) and cloudiness
    # (using solar radiation and clear sky radiation). The concentrations of all
    # other absorbers are assumed to be constant.
    #
    # The output can be converted to equivalent evaporation [mm day-1] using energy_to_evap.
    #
    # Based on FAO equation 39 in Allen et al (1998).
    #
    # @param tmin [Float] Absolute daily minimum temperature (degrees Kelvin)
    # @param albedo [Float] Absolute daily maximum temperature (degrees Kelvin)
    # @param sol_rad [Float] Solar radiation (MJ m-2 day-1). If necessary this
    #   can be estimated using methods with names beginning with sol_rad
    # @param cs_rad [Float] Clear sky radiation (MJ m-2 day-1). Can be estimated
    #   using cs_rad
    # @param avp [Float] Actual vapour pressure (kPa). Can be estimated using
    #   methods with names beginning with avp_from
    # @return [Float] Net outgoing longwave radiation (MJ m-2 day-1)
    def self.net_out_lw_rad(tmin, tmax, sol_rad, cs_rad, avp)
      tmp1 = (STEFAN_BOLTZMANN_CONSTANT * (((tmax.to_f ** 4) + (tmin.to_f ** 4)) / 2))
      tmp2 = (0.34 - (0.14 * Math.sqrt(avp.to_f)))
      tmp3 = 1.35 * (sol_rad.to_f / cs_rad.to_f) - 0.35
      return tmp1.to_f * tmp2.to_f * tmp3.to_f
    end

    # Calculate daily net radiation at the crop surface, assuming a grass
    # reference crop.
    #
    # Net radiation is the difference between the incoming net shortwave (or
    # solar) radiation and the outgoing net longwave radiation. Output can be
    # converted to equivalent evaporation [mm day-1] using energy_to_evap.
    #
    # Based on equation 40 in Allen et al (1998).
    #
    # @param ni_sw_rad [Float] Net incoming shortwave radiation (MJ m-2 day-1).
    #   Can be estimated using net_in_sol_rad
    # @param no_lw_rad [Float] Net outgoing longwave radiation (MJ m-2 day-1).
    #   Can be estimated using net_out_lw_rad
    # @return [Float] Daily net radiation (MJ m-2 day-1)
    def self.net_rad(ni_sw_rad, no_lw_rad)
      return ni_sw_rad.to_f - no_lw_rad.to_f
    end

    # Calculate the psychrometric constant.
    #
    # This method assumes that the air is saturated with water vapour at the
    # minimum daily temperature. This assumption may not hold in arid areas.
    #
    # Based on equation 8, page 95 in Allen et al (1998).
    #
    # @param atmos_pres [Float] Atmospheric pressure (kPa). Can be estimated
    #   using atm_pressure
    # @return [Float] Psychrometric constant (kPa degC-1)
    def self.psy_const(atmos_pres)
      return 0.000665 * atmos_pres.to_f
    end

    # Calculate the psychrometric constant for different types of
    # psychrometer at a given atmospheric pressure.
    #
    # Based on FAO equation 16 in Allen et al (1998).
    #
    # psychrometer types:
    # 1. ventilated (Asmann or aspirated type) psychrometer with an air movement of approximately 5 m/s
    # 2. natural ventilated psychrometer with an air movement of approximately 1 m/s
    # 3. non ventilated psychrometer installed indoors
    #
    # @param psychrometer [Float] Integer between 1 and 3 which denotes type of
    #   psychrometer
    # @param atmos_pres [Float] Atmospheric pressure [kPa]. Can be estimated
    #   using atm_pressure
    # @return [Float] Psychrometric constant (kPa degC-1)
    def self.psy_const_of_psychrometer(psychrometer, atmos_pres)
      # Select coefficient based on type of ventilation of the wet bulb
      case psychrometer
      when 1
        psy_coeff = 0.000662
      when 2
        psy_coeff = 0.000800
      when 3
        psy_coeff = 0.001200
      else
        raise ArgumentError.new("psychrometer should be in range 1 to 3: #{psychrometer}")
      end

      return psy_coeff.to_f * atmos_pres.to_f
    end

    # Calculate relative humidity as the ratio of actual vapour pressure
    # to saturation vapour pressure at the same temperature.
    #
    # See Allen et al (1998), page 67 for details.
    #
    # @param avp [Float] Actual vapour pressure (units do not matter so long as
    #   they are the same as for *svp*). Can be estimated using methods whose
    #   name begins with avp_from
    # @param svp [Float] Saturated vapour pressure (units do not matter so long
    #   as they are the same as for *avp*). Can be estimated using svp_from_t
    # @return [Float] Relative humidity (%)
    def self.rh_from_avp_svp(avp, svp)
      return 100.0 * avp.to_f / svp.to_f
    end

    # Calculate solar declination from day of the year.
    #
    # Based on FAO equation 24 in Allen et al (1998).
    #
    # @param day_of_year [Integer] Day of year integer between 1 and 365 or 366
    # @return [Float] solar declination (radians)
    def self.sol_dec(day_of_year)
      Validation.check_doy(day_of_year)
      return 0.409 * Math.sin(((2.0 * Math::PI / 365.0) * day_of_year.to_f - 1.39))
    end

    # Calculate incoming solar (or shortwave) radiation, *Rs* (radiation hitting
    # a horizontal plane after scattering by the atmosphere) from relative
    # sunshine duration.
    #
    # If measured radiation data are not available this method is preferable
    # to calculating solar radiation from temperature. If a monthly mean is
    # required then divide the monthly number of sunshine hours by number of
    # days in the month and ensure that *et_rad* and *daylight_hours* was
    # calculated using the day of the year that corresponds to the middle of
    # the month.
    #
    # Based on equations 34 and 35 in Allen et al (1998).
    #
    # @param dl_hours [Integer] Number of daylight hours (hours). Can be
    #   calculated using daylight_hours()
    # @param sunshine_hours [Integer] Sunshine duration (hours). Can be
    #   calculated using sunshine_hours()
    # @param et_rad [Float] Extraterrestrial radiation (MJ m-2 day-1). Can be
    #   estimated using et_rad()
    # @return [Float] Incoming solar (or shortwave) radiation (MJ m-2 day-1)
    def self.sol_rad_from_sun_hours(daylight_hours, sunshine_hours, et_rad)
      Validation.check_day_hours(sunshine_hours, 'sun_hours')
      Validation.check_day_hours(daylight_hours, 'daylight_hours')

      # 0.5 and 0.25 are default values of regression constants (Angstrom values)
      # recommended by FAO when calibrated values are unavailable.
      return (0.5 * sunshine_hours.to_f / daylight_hours.to_f + 0.25) * et_rad.to_f
    end

    # Estimate incoming solar (or shortwave) radiation, *Rs*, (radiation hitting
    # a horizontal plane after scattering by the atmosphere) from min and max
    # temperature together with an empirical adjustment coefficient for
    # 'interior' and 'coastal' regions.
    #
    # The formula is based on equation 50 in Allen et al (1998) which is the
    # Hargreaves radiation formula (Hargreaves and Samani, 1982, 1985). This
    # method should be used only when solar radiation or sunshine hours data are
    # not available. It is only recommended for locations where it is not
    # possible to use radiation data from a regional station (either because
    # climate conditions are heterogeneous or data are lacking).
    #
    # **NOTE**: this method is not suitable for island locations due to the
    # moderating effects of the surrounding water.
    #
    # @param et_rad [Float] Extraterrestrial radiation (MJ m-2 day-1). Can be
    #   estimated using et_rad()
    # @param cs_rad [Float] Clear sky radiation (MJ m-2 day-1). Can be estimated
    #   using cs_rad()
    # @param tmin [Float] Daily minimum temperature (deg C)
    # @param tmax [Float] Daily maximum temperature (deg C)
    # @param coastal [Boolean] True if site is a coastal location, situated on
    #   or adjacent to coast of a large land mass and where air masses are
    #   influenced by a nearby water body, False if interior location where land
    #   mass dominates and air masses are not strongly influenced by a large
    #   water body.
    # @return [Float] Incoming solar (or shortwave) radiation (Rs) (MJ m-2 day-1)
    def self.sol_rad_from_t(et_rad, cs_rad, tmin, tmax, coastal)
      # Determine value of adjustment coefficient [deg C-0.5] for
      # coastal/interior locations
      adj = coastal ? 0.19 : 0.16

      sol_rad = adj.to_f * Math.sqrt(tmax.to_f - tmin.to_f) * et_rad.to_f

      # The solar radiation value is constrained by the clear sky radiation
      return [sol_rad.to_f, cs_rad.to_f].min
    end

    # Estimate incoming solar (or shortwave) radiation, *Rs* (radiation hitting
    # a horizontal plane after scattering by the atmosphere) for an island
    # location.
    #
    # An island is defined as a land mass with width perpendicular to the
    # coastline <= 20 km. Use this method only if radiation data from
    # elsewhere on the island is not available.
    #
    # **NOTE**: This method is only applicable for low altitudes (0-100 m)
    # and monthly calculations.
    #
    # Based on FAO equation 51 in Allen et al (1998).
    #
    # @param et_rad [Float] Extraterrestrial radiation (MJ m-2 day-1). Can be
    #   estimated using et_rad()
    # @return [Float] Incoming solar (or shortwave) radiation (MJ m-2 day-1)
    def self.sol_rad_island(et_rad)
      return (0.7 * et_rad.to_f) - 4.0
    end

    # Calculate sunset hour angle (*Ws*) from latitude and solar
    # declination.
    #
    # Based on FAO equation 25 in Allen et al (1998).
    #
    # @param latitude [Float] Latitude (radians). Note: *latitude* should be
    #   negative if it in the southern hemisphere, positive if in the northern
    #   hemisphere
    # @param sol_dec [Float] Solar declination (radians). Can be calculated
    #   using sol_dec()
    # @return [Float] Sunset hour angle (radians)
    def self.sunset_hour_angle(latitude, sol_dec)
      Validation.check_latitude_rad(latitude)
      Validation.check_sol_dec_rad(sol_dec)

      cos_sha = -Math.tan(latitude.to_f) * Math.tan(sol_dec.to_f)
      # If tmp is >= 1 there is no sunset, i.e. 24 hours of daylight
      # If tmp is <= 1 there is no sunrise, i.e. 24 hours of darkness
      # See http://www.itacanet.org/the-sun-as-a-source-of-energy/
      # part-3-calculating-solar-angles/
      # Domain of acos is -1 <= x <= 1 radians (this is not mentioned in FAO-56!)
      return Math.acos([[cos_sha.to_f, -1.0].max, 1.0].min)
    end

    # Estimate saturation vapour pressure (*es*) from air temperature.
    #
    # Based on equations 11 and 12 in Allen et al (1998).
    #
    # @param t [Float] Temperature (deg C)
    # @return [Float] Saturation vapour pressure (kPa)
    def self.svp_from_t(t)
      return 0.6108 * Math.exp((17.27 * t.to_f) / (t.to_f + 237.3))
    end

    # Convert wind speed measured at different heights above the soil
    # surface to wind speed at 2 m above the surface, assuming a short grass
    # surface.
    #
    # Based on FAO equation 47 in Allen et al (1998).
    #
    # @param ws [Float] Measured wind speed (m s-1)
    # @param z [Float] Height of wind measurement above ground surface (m)
    # @return [Float] Wind speed at 2 m above the surface (m s-1)
    def self.wind_speed_2m(ws, z)
      return ws.to_f * (4.87 / Math.log((67.8 * z.to_f) - 5.42))
    end

  end
end
