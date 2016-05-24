require 'rest-client'

class HomeController < ApplicationController

	def index
		response = RestClient.get 'https://blockchain.info/charts/market-price?showDataPoints=false&timespan=all&show_header=true&daysAverageString=1&scale=0&format=json&address='

		@data = response.to_str
		@test = "test"

		print "%s\n"
		print "%s\n" % @data
	end
end
