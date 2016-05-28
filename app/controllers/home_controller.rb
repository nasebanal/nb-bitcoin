require 'rest-client'
require 'json'
require 'date'

class HomeController < ApplicationController

	def index
		@duration = params[:duration]	|| "30days"
		@amount = params[:amount] || 100

		@url = "https://blockchain.info/charts/market-price?showDataPoints=false&timespan=%s&show_header=true&daysAverageString=1&scale=0&format=json&address=" % @duration

		response = RestClient.get @url

		@json_data = JSON.parse(response)['values']
		@timeseries_data = []
		@records = []
		@beps = []
		@beps_data = []
		counter = 0

		@json_data.each do |p|
			@timeseries_data.push([p['x']*1000, p['y']])

			record = Hash.new
			record['date'] = Time.at(p['x']*1000)
			record['value'] = p['y']

			@records.push(record)
		end

		for amount in 1..1000 do

			bep = Hash.new
			bep['amount'] = amount

			if amount < 5000
				bep['transferwise'] = amount * 0.01 + 3
			else
				bep['transferwise'] = 5000 * 0.007 + (amount - 5000) * 0.01 + 3
			end

			if amount < 1000000
				bep['bitcoin'] = amount * 0.01
			else
				be['bitcoin'] = amount * 0.02
			end

			@beps_data.push([amount, bep['bitcoin'], bep['transferwise']])
			@beps.push(bep)
		end

		# comment out
=begin
		R.eval <<-EOF
			test<-as.numeric(1+1)
EOF
		@test = R.test
=end

		@timeseries_chart = LazyHighCharts::HighChart.new('graph') do |f|
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
				data: @timeseries_data
			)
			f.chart({:defaultSeriesType=>"line"})
		end

    @bep_chart = LazyHighCharts::HighChart.new('graph') do |f|
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
        data: @timeseries_data
      )
      f.chart({:defaultSeriesType=>"line"})
    end

	end
end
