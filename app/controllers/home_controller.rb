require 'rest-client'

class HomeController < ApplicationController

	def index
		response = RestClient.get 'https://blockchain.info/charts/market-price?showDataPoints=false&timespan=all&show_header=true&daysAverageString=1&scale=0&format=json&address='

		@data = response.to_str

		@chart = LazyHighCharts::HighChart.new('graph') do |f|
			f.title(:text => "Population vs GDP For 5 Big Countries [2009]")
			f.xAxis(:categories => ["United States", "Japan", "China", "Germany", "France"])
			f.series(:name => "GDP in Billions", :yAxis => 0, :data => [14119, 5068, 4985, 3339, 2656])
			f.series(:name => "Population in Millions", :yAxis => 1, :data => [310, 127, 1340, 81, 65])

			f.yAxis [
				{:title => {:text => "GDP in Billions", :margin => 70} },
				{:title => {:text => "Population in Millions"}, :opposite => true},
 ]

			f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
			f.chart({:defaultSeriesType=>"column"})
		end

		print "%s\n"
		print "%s\n" % @data
	end
end
