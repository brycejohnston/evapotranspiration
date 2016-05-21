require "conversion"

module Evapotranspiration
  module Validation

    # Latitude
    MINLAT_RADIANS = Conversion.deg_to_rad(-90.0)
    MAXLAT_RADIANS = Conversion.deg_to_rad(90.0)

    # Solar declination
    MINSOLDEC_RADIANS = Conversion.deg_to_rad(-23.5)
    MAXSOLDEC_RADIANS = Conversion.deg_to_rad(23.5)

    # Sunset hour angle
    MINSHA_RADIANS = 0.0
    MAXSHA_RADIANS = Conversion.deg_to_rad(180)

    # Check that *hours* is in the range 1 to 24
    def self.check_day_hours(hours, arg_name)
      unless hours.between?(0,24)
        raise ArgumentError.new("#{arg_name} should be in the range 0-24: #{hours}")
      end
    end

    # Check day of the year is valid
    def self.check_doy(doy)
      unless doy.between?(1,366)
        raise ArgumentError.new("day of the year (doy) must be in range 1-366: #{doy}")
      end
    end

    def self.check_latitude_rad(latitude)
      unless latitude.between?(MINLAT_RADIANS,MAXLAT_RADIANS)
        raise ArgumentError.new("latitude outside valid range #{MINLAT_RADIANS} to #{MAXLAT_RADIANS} rad: #{latitude}")
      end
    end

    # Solar declination can vary between -23.5 and +23.5 degrees.
    # See http://mypages.iit.edu/~maslanka/SolarGeo.pdf
    def self.check_sol_dec_rad(sd)
      unless sd.between?(MINSOLDEC_RADIANS,MAXSOLDEC_RADIANS)
        raise ArgumentError.new("solar declination outside valid range #{MINSOLDEC_RADIANS} to #{MAXSOLDEC_RADIANS} rad: #{sd}")
      end
    end

    # Sunset hour angle has the range 0 to 180 degrees.
    # See http://mypages.iit.edu/~maslanka/SolarGeo.pdf
    def self.check_sunset_hour_angle_rad(sha)
      unless sha.between?(MINSHA_RADIANS,MAXSHA_RADIANS)
        raise ArgumentError.new("sunset hour angle outside valid range #{MINSHA_RADIANS} to #{MAXSHA_RADIANS} rad: #{sha}")
      end
    end

  end
end
