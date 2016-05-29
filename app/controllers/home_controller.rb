require 'rest-client'
require 'json'
require 'descriptive-statistics'
require 'date'

class HomeController < ApplicationController

	def index

		#======= Get Prameters =======

		@duration = params[:duration]	|| "30days"
		@amount = params[:amount] || 100


		#======= Get Bitcoin Data =======

		@url = "https://blockchain.info/charts/market-price?showDataPoints=false&timespan=%s&show_header=true&daysAverageString=1&scale=0&format=json&address=" % @duration

		response = RestClient.get @url
		@json_data = JSON.parse(response)['values']


		#======= Prepare data for Time Series Analysis =======

    timeseries_data = []
    timeseries_ave = []
    timeseries_hist = DescriptiveStatistics::Stats.new([0, 0, 0, 0, 0])
    timeseries_diff = []
		differential_data = []
		differential_ave = []
    @timeseries_record = []
    counter = 0
    prev_data = 0
		prev_ave = 0

		@json_data.each do |p|

			data = Hash.new
			data['date'] = Time.at(p['x']*1000)
			data['value'] = p['y']

			timeseries_hist.push(data['value'])
      timeseries_hist.shift(1)

			if counter > 4
				data['moving_ave'] = timeseries_hist.mean
			else
				data['moving_ave'] = data['value']
				prev_ave = data['value']
			end


			#----- Setup Array Data for Time Series Analysis -----

			timeseries_data.push([p['x']*1000, p['y']])

			#----- Setup Array Data for Differential Analysis -----

			if counter > 0
				timeseries_diff.push(data['value']-prev_data)
				differential_data.push([p['x']*1000, data['value']-prev_data])
			else
				timeseries_diff.push(0)
				differential_data.push([p['x']*1000, 0])
			end

			#----- Setup Array Data for Moving Average -----

      timeseries_ave.push([p['x']*1000, data['moving_ave']])
			differential_ave.push([p['x']*1000, data['moving_ave']-prev_ave])

			@timeseries_record.push(data)
			counter = counter+1
			prev_data = data['value']
			prev_ave = data['moving_ave']
		end

		curr_rate = timeseries_hist[4]


		#======= Prepare Data for Descriptive Statistics =======

		@stats_record = []
		stats_diff = DescriptiveStatistics::Stats.new(timeseries_diff)


		#======= Prepare Data for Break Even Point =======

    @bep_coinbase = []
    @bep_coinbase_upper_1std = []
    @bep_coinbase_lower_1std = []
    @bep_coinbase_upper_2std = []
    @bep_coinbase_lower_2std = []
    @bep_transferwise = []
    @bep_record = []

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

			data['coinbase_upper_1std'] = data['coinbase'] + stats_diff.mean + stats_diff.standard_deviation / curr_rate * amount
			data['coinbase_lower_1std'] = data['coinbase'] + stats_diff.mean - stats_diff.standard_deviation / curr_rate * amount
			data['coinbase_upper_2std'] = data['coinbase'] + stats_diff.mean + stats_diff.standard_deviation / curr_rate * amount * 2
			data['coinbase_lower_2std'] = data['coinbase'] + stats_diff.mean - stats_diff.standard_deviation / curr_rate * amount * 2

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

		#======= Create Chart Data for Time Series Analysis =======

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
				lineWidth: 2,
				data: timeseries_ave
			)
      f.chart({:defaultSeriesType=>"line"})
    end

		#======= Create Chart Data for Differential Analysis =======

		@diff_chart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title(text: "The Differential of Bitcoin")
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
        data: differential_data
      )
			f.series(
        name: "Moving Average",
        yAxis: 0,
				lineWidth: 2,
        data: differential_ave
      )
			f.chart({:defaultSeriesType=>"line"})
    end


		#======= Create Chart Data for Break Even Analysis

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
