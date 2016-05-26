require 'rest-client'
require 'json'

class HomeController < ApplicationController

	def index
		response = RestClient.get 'https://blockchain.info/charts/market-price?showDataPoints=false&timespan=all&show_header=true&daysAverageString=1&scale=0&format=json&address='

#		@data = response

		@data_temp = JSON.parse(response)['values']
		@data = []
		@data_temp.each do |p|
			@data.push([p['x'], p['y']])
		end

		@chart = LazyHighCharts::HighChart.new('graph') do |f|
			f.title(:text => "The Market Price of Bitcoin")
			f.subtitle(text: "source: blockchain.info")
			f.xAxis(type: 'datetime')
			f.yAxis [
        {:title => {:text => "Value [USD]"} },
 ]
			f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
			f.plotOptions(area: {
				marker: {
					radius: 0
				},
				lineWidth: 1,
				states: {
					hover: {
						lineWidth: 1
					}
				}
			})
			f.series(
				name: "Bitcoin", 
				yAxis: 0, 
				data: @data
			)
			f.chart({:defaultSeriesType=>"area"})
		end

	end
end
