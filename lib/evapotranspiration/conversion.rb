module Evapotranspiration
  module Conversion

    # Convert temperature in degrees Celsius to degrees Kelvin
    #
    # @param celsius [Float] Degrees Celsius
    # @return [Float] Degrees Kelvin
    def self.celsius_to_kelvin(celsius)
      celsius.to_f + 273.15
    end

    # Convert temperature in degrees Kelvin to degrees Celsius
    #
    # @param kelvin [Float] Degrees Kelvin
    # @return [Float] Degrees Celsius
    def self.kelvin_to_celsius(kelvin)
      kelvin.to_f - 273.15
    end

    # Convert angular degrees to radians
    #
    # @param degrees [Float] Value in degrees to be converted
    # @return [Float] Value in radians
    def self.deg_to_rad(degrees)
      degrees.to_f * (Math::PI / 180.0)
    end

    # Convert radians to angular degrees
    #
    # @param radians [Float] Value in radians to be converted
    # @return [Float] Value in angular degrees
    def self.rad_to_deg(radians)
      radians.to_f * (180.0 / Math::PI)
    end

    # Convert km/hr to m/s
    #
    # @param kph [Float] Kilometers per hour
    # @return [Float] Meters per second
    def self.kph_to_mps(kph)
      (kph.to_f * 1000) / 3600
    end

  end
end
