require 'rest-client'
require 'json'
require 'descriptive-statistics'
require 'date'

class HomeController < ApplicationController

	def index
		@duration = params[:duration]	|| "30days"
		@amount = params[:amount] || 100

		@url = "https://blockchain.info/charts/market-price?showDataPoints=false&timespan=%s&show_header=true&daysAverageString=1&scale=0&format=json&address=" % @duration

		response = RestClient.get @url

		@json_data = JSON.parse(response)['values']
		timeseries_data = []
		timeseries_ave = []
		timeseries_hist = DescriptiveStatistics::Stats.new([0, 0, 0, 0, 0])
		timeseries_diff = []
		@timeseries_record = []
		@bep_coinbase = []
		@bep_coinbase_upper_1std = []
		@bep_coinbase_lower_1std = []
		@bep_coinbase_upper_2std = []
		@bep_coinbase_lower_2std = []
		@bep_transferwise = []
		@bep_record = []
		counter = 0
		prev_data = 0

		@json_data.each do |p|
			timeseries_data.push([p['x']*1000, p['y']])

			data = Hash.new
			data['date'] = Time.at(p['x']*1000)
			data['value'] = p['y']

			timeseries_hist.push(data['value'])
      timeseries_hist.shift(1)
			data['moving_ave'] = timeseries_hist.mean

			if counter > 4
				timeseries_ave.push([p['x']*1000, data['moving_ave']])
			else
				timeseries_ave.push([p['x']*1000, data['value']])
			end

			timeseries_diff.push(data['value']-prev_data)

			@timeseries_record.push(data)
			counter = counter+1
			prev_data = data['value']
		end

		(1..10000).step(100) {|amount|

			data = Hash.new
			data['amount'] = amount

			if amount < 5000
				data['transferwise'] = amount * 0.01 + 3
			else
				data['transferwise'] = 5000 * 0.01 + (amount - 5000) * 0.007 + 3
			end

			if amount < 1000000
				data['coinbase'] = amount * 0.01
			else
				data['coinbase'] = 1000000 * 0.01 + (amount - 1000000) * 0.02
			end

			stats = DescriptiveStatistics::Stats.new(timeseries_diff)

			data['coinbase_upper_1std'] = data['coinbase'] + stats.standard_deviation
			data['coinbase_lower_1std'] = data['coinbase'] - stats.standard_deviation
			data['coinbase_upper_2std'] = data['coinbase'] + stats.standard_deviation*2
			data['coinbase_lower_2std'] = data['coinbase'] - stats.standard_deviation*2

			if data['coinbase'] < data['transferwise']
				data['winner'] = 'Coinbase'
			else
				data['winner'] = 'Transferwise'
			end

			@bep_coinbase.push([amount, data['coinbase']])
			@bep_coinbase_upper_1std.push([amount, data['coinbase_upper_1std']])
			@bep_coinbase_lower_1std.push([amount, data['coinbase_lower_1std']])
			@bep_coinbase_upper_2std.push([amount, data['coinbase_upper_2std']])
			@bep_coinbase_lower_2std.push([amount, data['coinbase_lower_2std']])
			@bep_transferwise.push([amount, data['transferwise']])
			@bep_record.push(data)
		}

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
        name: "Actual Data",
        yAxis: 0,
        data: timeseries_data
      )
			f.series(
				name: "Moving Average",
				yAxis: 0,
				data: timeseries_ave
			)
      f.chart({:defaultSeriesType=>"line"})
    end

		@bep_chart = LazyHighCharts::HighChart.new('graph') do |f|
			f.title(text: "Break Even Point between Coinbase and Transferwise")
			f.xAxis({title: {text: "Amount [USD]"}, type: 'number'})
			f.yAxis [
        {title: {text: "Fee [USD]"}, showFirstLabel: false },
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
				name: "Coinbase", 
				data: @bep_coinbase,
				lineWidth: 2
			)
			f.series(
				name: "Transferwise",
				data: @bep_transferwise,
				lineWidth: 2
			)
			f.series(
        name: "Coinbase (Upper 1STD)",
        data: @bep_coinbase_upper_1std,
				dashStyle: 'longdash'
      )
			f.series(
        name: "Coinbase (Lower 1STD)",
        data: @bep_coinbase_lower_1std,
				dashStyle: 'longdash'
      )
=begin
			f.series(
        name: "Coinbase (Upper 2STD)",
        data: @bep_coinbase_upper_2std
      )
			f.series(
        name: "Coinbase (Lower 2STD)",
        data: @bep_coinbase_lower_2std
      )
=end
			f.chart({:defaultSeriesType=>"line"})
		end
	end
end
