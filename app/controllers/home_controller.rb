require 'rest-client'
require 'json'

class HomeController < ApplicationController

	def index
		@duration = params[:duration]	

		@url = "https://blockchain.info/charts/market-price?showDataPoints=false&timespan=%s&show_header=true&daysAverageString=1&scale=0&format=json&address=" % @duration

		response = RestClient.get @url

		@data_temp = JSON.parse(response)['values']
		@data = []
		@data_temp.each do |p|
			@data.push([p['x']*1000, p['y']])
		end

		# comment out
=begin
		R.eval <<-EOF
			test<-as.numeric(1+1)
EOF
		@test = R.test
=end

		@chart = LazyHighCharts::HighChart.new('graph') do |f|
			f.title(text: "The Market Price of Bitcoin")
			f.subtitle(text: "source: blockchain.info")
			f.xAxis(type: 'datetime')
			f.yAxis [
        {title: {text: "Value [USD]"}, showFirstLabel: false },
 ]
			f.legend(align: 'right', verticalAlign: 'top', y: 75, x: -50, layout: 'vertical',)
			f.plotOptions(line: {
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
			f.chart({:defaultSeriesType=>"line"})
		end

	end
end
