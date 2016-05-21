module Evapotranspiration
  class FAO

    # Solar constant [ MJ m-2 min-1]
    SOLAR_CONSTANT = 0.0820

    # Stefan Boltzmann constant [MJ K-4 m-2 day-1]
    STEFAN_BOLTZMANN_CONSTANT = 0.000000004903

    def atm_pressure(altitude)
    end

    def avp_from_tmin(tmin)
    end

    def avp_from_rhmin_rhmax(svp_tmin, svp_tmax, rh_min, rh_max)
    end

    def avp_from_rhmax(svp_tmin, rh_max)
    end

    def avp_from_rhmean(svp_tmin, svp_tmax, rh_mean)
    end

    def avp_from_tdew(tdew)
    end

    def avp_from_twet_tdry(twet, tdry, svp_twet, psy_const)
    end

    def cs_rad(altitude, et_rad)
    end

    def daily_mean_t(tmin, tmax)
    end

    def daylight_hours(sha)
    end

    def delta_svp(t)
    end

    def energy2evap(energy)
    end

    def et_rad(latitude, sol_dec, sha, ird)
    end

    def fao56_penman_monteith(net_rad, t, ws, svp, avp, delta_svp, psy, shf=0.0)
    end

    def hargreaves(tmin, tmax, tmean, et_rad)
    end

    def inv_rel_dist_earth_sun(day_of_year)
    end

    def mean_svp(tmin, tmax)
    end

    def monthly_soil_heat_flux(t_month_prev, t_month_next)
    end

    def monthly_soil_heat_flux2(t_month_prev, t_month_cur)
    end

    def net_in_sol_rad(sol_rad, albedo=0.23)
    end

    def net_out_lw_rad(tmin, tmax, sol_rad, cs_rad, avp)
    end

    def net_rad(ni_sw_rad, no_lw_rad)
    end

    def psy_const(atmos_pres)
    end

    def psy_const_of_psychrometer(psychrometer, atmos_pres)
    end

    def rh_from_avp_svp(avp, svp)
    end

    def sol_dec(day_of_year)
    end

    def sol_rad_from_sun_hours(daylight_hours, sunshine_hours, et_rad)
    end

    def sol_rad_from_t(et_rad, cs_rad, tmin, tmax, coastal)
    end

    def sol_rad_island(et_rad)
    end

    def sunset_hour_angle(latitude, sol_dec)
    end

    def svp_from_t(t)
    end

    def wind_speed_2m(ws, z)
    end

  end
end
