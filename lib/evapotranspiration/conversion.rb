module Evapotranspiration
  module Conversion

    # Convert temperature in degrees Celsius to degrees Kelvin
    #
    # @param celsius [Float] Degrees Celsius
    # @return [Float] Degrees Kelvin
    def self.celsius_to_kelvin(celsius)
      celsius + 273.15
    end

    # Convert temperature in degrees Kelvin to degrees Celsius
    #
    # @param kelvin [Float] Degrees Kelvin
    # @return [Float] Degrees Celsius
    def self.kelvin_to_celsius(kelvin)
      kelvin - 273.15
    end

    # Convert angular degrees to radians
    #
    # @param degrees [Float] Value in degrees to be converted
    # @return [Float] Value in radians
    def self.deg_to_rad(degrees)
      degrees * (Math::PI / 180.0)
    end

    # Convert radians to angular degrees
    #
    # @param radians [Float] Value in radians to be converted
    # @return [Float] Value in angular degrees
    def self.rad_to_deg(radians)
      radians * (180.0 / Math::PI)
    end

  end
end
