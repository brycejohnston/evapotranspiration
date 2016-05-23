require "validation"

module Evapotranspiration

  # Methods for estimating reference evapotransporation (ETo) for
  # a grass reference crop using the FAO-56 Penman-Monteith and Hargreaves
  # equations. The library includes numerous functions for estimating missing
  # meteorological data.
  module FAO

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
      tmp = (293.0 - (0.0065 * altitude)) / 293.0
      return (tmp ** 5.26) * 101.3
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
      0.611 * Math.exp((17.27 * tmin) / (tmin + 237.3))
    end

    # Estimate actual vapour pressure (*ea*) from saturation vapour pressure and
    # relative humidity.
    #
    # Based on FAO equation 17 in Allen et al (1998).
    #
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum temperature (kPa). Can be estimated using svp_from_t()
    # @param svp_tmax [Float] Saturation vapour pressure at daily maximum temperature (kPa). Can be estimated using svp_from_t()
    # @param rh_min [Float] Minimum relative humidity (%)
    # @param rh_max [Float] Maximum relative humidity (%)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmin_rhmax(svp_tmin, svp_tmax, rh_min, rh_max)
      tmp1 = svp_tmin * (rh_max / 100.0)
      tmp2 = svp_tmax * (rh_min / 100.0)
      return (tmp1 + tmp2) / 2.0
    end

    # Estimate actual vapour pressure (*ea*) from saturation vapour pressure at
    # daily minimum and maximum temperature, and mean relative humidity.
    #
    # Based on FAO equation 19 in Allen et al (1998).
    #
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum temperature (kPa). Can be estimated using svp_from_t()
    # @param rh_max [Float] Maximum relative humidity (%)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmax(svp_tmin, rh_max)
      svp_tmin * (rh_max / 100.0)
    end

    # Estimate actual vapour pressure (*e*a) from saturation vapour pressure at
    # daily minimum temperature and maximum relative humidity.
    #
    # Based on FAO equation 18 in Allen et al (1998).
    #
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum temperature (kPa). Can be estimated using svp_from_t()
    # @param svp_tmax [Float] Saturation vapour pressure at daily maximum temperature (kPa). Can be estimated using svp_from_t()
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmean(svp_tmin, svp_tmax, rh_mean)
      (rh_mean / 100.0) * ((svp_tmax + svp_tmin) / 2.0)
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
      0.6108 * Math.exp((17.27 * tdew) / (tdew + 237.3))
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
    # can be calculated using psyc_const_of_psychrometer().
    #
    # @param twet [Float] Wet bulb temperature (deg C)
    # @param tdry [Float] Dry bulb temperature (deg C)
    # @param svp_twet [Float] Saturated vapour pressure at the wet bulb temperature (kPa). Can be estimated using svp_from_t()
    # @param psy_const [Float] Psychrometric constant of the pyschrometer (kPa deg C-1). Can be estimated using psy_const() or psy_const_of_psychrometer()
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_twet_tdry(twet, tdry, svp_twet, psy_const)
      svp_twet - (psy_const * (tdry - twet))
    end

    # Estimate clear sky radiation from altitude and extraterrestrial radiation.
    #
    # Based on equation 37 in Allen et al (1998) which is recommended when
    # calibrated Angstrom values are not available.
    #
    # @param altitude [Float] Elevation above sea level (m)
    # @param et_rad [Float] Extraterrestrial radiation (MJ m-2 day-1). Can be estimated using et_rad()
    # @return [Float] Clear sky radiation (MJ m-2 day-1)
    def self.cs_rad(altitude, et_rad)
      (0.00002 * altitude + 0.75) * et_rad
    end

    # Estimate mean daily temperature from the daily minimum and maximum
    # temperatures.
    #
    # @param tmin [Float] Minimum daily temperature (deg C)
    # @param tmax [Float] Maximum daily temperature (deg C)
    # @return [Float] Mean daily temperature (deg C)
    def self.daily_mean_t(tmin, tmax)
      (tmax + tmin) / 2.0
    end

    # Calculate daylight hours from sunset hour angle.
    #
    # Based on FAO equation 34 in Allen et al (1998).
    #
    # @param sha [Float] Sunset hour angle (rad). Can be calculated using sunset_hour_angle()
    # @return [Float] Daylight hours
    def self.daylight_hours(sha)
      Validation.check_sunset_hour_angle_rad(sha)
      return (24.0 / Math::PI) * sha
    end

    # Estimate the slope of the saturation vapour pressure curve at a given
    # temperature.
    #
    # Based on equation 13 in Allen et al (1998). If using in the Penman-Monteith
    # *t* should be the mean air temperature.
    #
    # @param t [Float] Air temperature (deg C). Use mean air temperature for use in Penman-Monteith
    # @return [Float] Saturation vapour pressure (kPa degC-1)
    def self.delta_svp(t)
      tmp = 4098 * (0.6108 * Math.exp((17.27 * t) / (t + 237.3)))
      return tmp / ((t + 237.3) ** 2)
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
    def self.energy2evap(energy)
      0.408 * energy
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
    # @param sol_dec [Float] Solar declination (radians). Can be calculated using sol_dec()
    # @param sha [Float] Sunset hour angle (radians). Can be calculated using sunset_hour_angle()
    # @param ird [Float] Inverse relative distance earth-sun (dimensionless). Can be calculated using inv_rel_dist_earth_sun()
    # @return [Float] Daily extraterrestrial radiation (MJ m-2 day-1)
    def self.et_rad(latitude, sol_dec, sha, ird)
      Validation.check_latitude_rad(latitude)
      Validation.check_sol_dec_rad(sol_dec)
      Validation.check_sunset_hour_angle_rad(sha)

      tmp1 = (24.0 * 60.0) / Math::PI
      tmp2 = sha * Math.sin(latitude) * Math.sin(sol_dec)
      tmp3 = Math.cos(latitude) * Math.cos(sol_dec) * Math.sin(sha)
      return tmp1 * SOLAR_CONSTANT * ird * (tmp2 + tmp3)
    end

    def self.fao56_penman_monteith(net_rad, t, ws, svp, avp, delta_svp, psy, shf=0.0)
    end

    def self.hargreaves(tmin, tmax, tmean, et_rad)
    end

    def self.inv_rel_dist_earth_sun(day_of_year)
    end

    def self.mean_svp(tmin, tmax)
    end

    def self.monthly_soil_heat_flux(t_month_prev, t_month_next)
    end

    def self.monthly_soil_heat_flux2(t_month_prev, t_month_cur)
    end

    def self.net_in_sol_rad(sol_rad, albedo=0.23)
    end

    def self.net_out_lw_rad(tmin, tmax, sol_rad, cs_rad, avp)
    end

    def self.net_rad(ni_sw_rad, no_lw_rad)
    end

    def self.psy_const(atmos_pres)
    end

    def self.psy_const_of_psychrometer(psychrometer, atmos_pres)
    end

    def self.rh_from_avp_svp(avp, svp)
    end

    def self.sol_dec(day_of_year)
    end

    def self.sol_rad_from_sun_hours(daylight_hours, sunshine_hours, et_rad)
    end

    def self.sol_rad_from_t(et_rad, cs_rad, tmin, tmax, coastal)
    end

    def self.sol_rad_island(et_rad)
    end

    def self.sunset_hour_angle(latitude, sol_dec)
    end

    def self.svp_from_t(t)
    end

    def self.wind_speed_2m(ws, z)
    end

  end
end
