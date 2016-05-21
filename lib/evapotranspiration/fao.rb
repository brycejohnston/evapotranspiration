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
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum temperature
    # (kPa). Can be estimated using svp_from_t().
    # @param svp_tmax [Float] Saturation vapour pressure at daily maximum temperature
    # (kPa). Can be estimated using svp_from_t().
    # @param rh_min [Float] Minimum relative humidity (%)
    # @param rh_max [Float] Maximum relative humidity (%)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmin_rhmax(svp_tmin, svp_tmax, rh_min, rh_max)
      tmp1 = svp_tmin * (rh_max / 100.0)
      tmp2 = svp_tmax * (rh_min / 100.0)
      return (tmp1 + tmp2) / 2.0
    end

    # Estimate actual vapour pressure (*e*a) from saturation vapour pressure at
    # daily minimum temperature and maximum relative humidity
    #
    # Based on FAO equation 18 in Allen et al (1998).
    #
    # @param svp_tmin [Float] Saturation vapour pressure at daily minimum temperature
    # (kPa). Can be estimated using svp_from_t().
    # @param rh_max [Float] Maximum relative humidity (%)
    # @return [Float] Actual vapour pressure (kPa)
    def self.avp_from_rhmax(svp_tmin, rh_max)
      svp_tmin * (rh_max / 100.0)
    end

    def self.avp_from_rhmean(svp_tmin, svp_tmax, rh_mean)
    end

    def self.avp_from_tdew(tdew)
    end

    def self.avp_from_twet_tdry(twet, tdry, svp_twet, psy_const)
    end

    def self.cs_rad(altitude, et_rad)
    end

    def self.daily_mean_t(tmin, tmax)
    end

    def self.daylight_hours(sha)
    end

    def self.delta_svp(t)
    end

    def self.energy2evap(energy)
    end

    def self.et_rad(latitude, sol_dec, sha, ird)
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
