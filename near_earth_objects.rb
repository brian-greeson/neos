require 'faraday'
require 'figaro'
require 'pry'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects
  attr_reader :objects, :date

  def initialize(date)
    @date = date
    @uri = '/neo/rest/v1/feed'
    @objects = JSON.parse(neos_on_date.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end

  def neos_on_date
    connection.get(@uri)
  end

  def connection
    Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, api_key: ENV['nasa_api_key']}
    )
  end

  def largest_diameter
    @objects.map do |astroid|
      astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    end.max { |a,b| a<=> b}
  end

  def count
    @objects.count
  end

  def astroid_list
    @objects.map do |astroid|
      {
        name: astroid[:name],
        diameter: "#{astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i} ft",
        miss_distance: "#{astroid[:close_approach_data][0][:miss_distance][:miles].to_i} miles"
      }
    end
  end
end

