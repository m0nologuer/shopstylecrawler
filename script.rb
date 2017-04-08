require 'json'
require 'open-uri'

url = "http://api.shopstyle.com/api/v2/colors?pid=uid5201-35972399-51"
colors = JSON.parse(open(url).read())["colors"].collect{|entry| entry["name"]}
categories =  [ "Platforms", "Pumps", "Sandals", "Sneakers", "Wedges", "Wallets"]


categories.each do |category|
colors.each do |color|

category.gsub!(/\s+/, "+")
color.gsub!(/\s+/, "+")
query = "#{category}+#{color}"

100.times do |i|
offset = i*50
url = "http://api.shopstyle.com/api/v2/products?pid=uid5201-35972399-51&fts=#{query}&offset=#{offset}&limit=50"
products = JSON.parse(open(url).read())["products"]

products.each do |product|
p = Product.new(name: product["name"], category: product["category"], unbranded_name: product["unbrandedName"],retailer: product["retailer"], currency: product["currency"], price: product["price"], brand: product["brand"], description: product["description"], img: product["image"]["sizes"]["Original"]["url"], thumbnail: product["image"]["sizes"]["IPhoneSmall"]["url"], raw_xml: product.to_s)
p.save
end

end

end
end


Product.find_each do |product|
if (product.brand[0] == '{')
product.brand = JSON.parse(product.brand.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
product.retailer = JSON.parse(product.retailer.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
product.category = JSON.parse(product.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["categories"][0]["name"]
product.shopstyle_id = JSON.parse(product.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["id"]
product.save
end
end

categories = Product.pluck(:category).uniq
categories.each do |category|
Dir.mkdir("thumbnails/#{category}")
end

Product.find_each(start: 1260998) do |product|
filename = "thumbnails/#{product.category}/#{product.shopstyle_id}.jpg"
if File.file?(filename)
product.delete
else
open(filename, 'wb') do |file|
file << open(product.thumbnail).read
end
end
end

x = Product.first.brand.split(/([A-Z]|[0-9])/)
y = ((x.length-1)/2).times.collect {|i| x[2*i+1] + x[2*i+2]}.join(" ")
Product.first.description.gsub(y.join(" "), Product.first.brand)
regex = /\(*(size )*(\d+(\.)*\d*)((in|mm|cm)|'|-|\\"\w*|\/|%)*( wide)*;*( x )*\)*/
product.gsub(/<\/*\w*>/,'')
Product.first.description.gsub(regex,'')


x = product.brand.split(/([A-Z]|[0-9])/)
name = ((x.length-1)/2).times.collect {|i| x[2*i+1] + x[2*i+2]}.join(" ")

modified_name = name.gsub(/<\/*\w*>/,'').gsub(regex,'').gsub("\"",'')
desc = desc.gsub(modified_name, name + " " + product.brand)

regex = /\(*(size )*(\d+(\.)*\d*)((in|mm|cm)|'|-|\\"\w*|\/|%)*( wide)*;*( x )*\)*/
Product.all.find_each do |product|
desc = desc.gsub(/<\/*\w*>/,'').gsub(regex,'').gsub("\"",'').gsub(/[.,\/#!$%\^&\*;:{}=\_`~()]/,'')
product.description = desc
product.save
end

#UPDATE scipt
require 'json'
require 'open-uri'

url = "http://api.shopstyle.com/api/v2/colors?pid=uid5201-35972399-51"
colors = JSON.parse(open(url).read())["colors"].collect{|entry| entry["name"]}

colors.each do |color|

100.times do |i|
offset = i*50
url = "http://api.shopstyle.com/api/v2/products?pid=uid5201-35972399-51&fts=#{color}&offset=#{offset}&limit=50"
products = JSON.parse(open(url).read())["products"]

products.each do |product|
p = Product.new(name: product["name"], category: product["category"], unbranded_name: product["unbrandedName"],retailer: product["retailer"], currency: product["currency"], price: product["price"], brand: product["brand"], description: product["description"], img: product["image"]["sizes"]["Original"]["url"], thumbnail: product["image"]["sizes"]["IPhoneSmall"]["url"], raw_xml: product.to_s)
if (not p.brand.nil? and p.brand[0] == '{')
p.brand = JSON.parse(p.brand.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
p.retailer = JSON.parse(p.retailer.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
p.category = JSON.parse(p.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["categories"][0]["name"]
p.shopstyle_id = JSON.parse(p.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["id"]

filename = "thumbnails/#{p.category}/#{p.shopstyle_id}.jpg"
if not File.file?(filename)
open(filename, 'wb') do |file|
file << open(p.thumbnail).read
p.save
end
end
end

end
end
end

#Pre-owned/ rental script
preOwned = 0
rental = 0
checked = 0
Product.find_each do |product|
if product.raw_xml.include?("preOwned\"=>true")
product.preowned = true
product.rental = false
preOwned = preOwned + 1
elsif product.raw_xml.include?("rental\"=>true")
product.preowned = false
product.rental = true
rental = rental + 1
else
product.preowned = false
product.rental = false
checked = checked + 1
end
product.save
end


#Gender script
men = 0
women = 0
neither = 0
Product.find_each do |product|
if product.raw_xml.include?("Men's")
product.gender_male = true
product.gender_female = false
product.save
men = men + 1
elsif product.raw_xml.include?("Women's")
product.gender_female = true
product.gender_male = false
women = women + 1
product.save
else
neither = neither + 1
end
end


#Foursquare London location bulk downloader
client = Foursquare2::Client.new(:client_id => 'TPCIXU1RXNMRPZ1AP0ZJ5YXXDRANSWIHOSA5CKSQAFNFYPBK', :client_secret => '10MYXBP1T5QPNTLSUCDNEOLBVJB0AHXCJM2XXKSG5AP2T4NT')

x = 51.567
while x < 51.63051
y = -0.288
while y <  0.1
begin
response = client.search_venues(:ll => "#{x}, #{y}", :v=>"20170104")
response["venues"].each do |venue|
begin
new_v = Venue.new(name:venue["name"], category: venue["categories"][0]["name"], address: venue["location"]["address"], lat:venue["location"]["lat"], long: venue["location"]["lng"],checkinsCount: venue["stats"]["checkinsCount"], usersCount: venue["stats"]["usersCount"],tipCount: venue["stats"]["tipCount"])
new_v.save
rescue
end
end
rescue
print("rate limit exceeded")
sleep(15.minutes)
end
y+= 5e-4
end
x+= 5e-4
end

#remove dupes
class Venue

  def self.dedupe
    # find all models and group them on keys which should be common
    grouped = all.group_by{|model| [model.name,model.lat,model.long] }
    grouped.values.each do |duplicates|
      # the first one we want to keep right?
      first_one = duplicates.shift # or pop for last one
      # if there are any more left, they are duplicates
      # so delete all of them
      duplicates.each{|double| double.destroy} # duplicates can now be destroyed
    end
  end
end
Venue.dedupe

#Polyvore sets script
require 'nokogiri'
require 'open-uri'

(211279401..214279401).each do |id|
begin
###online bit
url = "http://www.polyvore.com/yeah_bunny/set?id=#{id}"
html_doc = Nokogiri::HTML(open(url))
set_items = html_doc.search(".grid_item")[1..-1]
set_items.each do |set_item|
product_name = set_item.css(".title").text
## Add to set?
##
if product_name == ""
break
end
end
#### end online bit
rescue
end

end


#Polyvore popularity script
require 'nokogiri'
require 'open-uri'

Product.where("id > ?", 200016).find_each do |product|
begin
search_name = product.name.gsub(" ","+").encode(Encoding.find('ASCII'), {:invalid => :replace, :undef   => :replace,:replace => ''})
url = "http://www.polyvore.com/cgi/shop?query=#{search_name}&.search_src=masthead_search"
html_doc = Nokogiri::HTML(open(url))
results = html_doc.search(".grid_item")
results.each do |result|
if result.css(".title").text == product.name
faves = result.css(".fav_count").text.to_i
product.faves = faves
product.save
break
end
end
rescue
end
end

#Imagemagick

for d in ./*/ ; do (cd "$d" && mogrify -background white -gravity center -extent 128x128  *.jpg); done
mogrify -background white -gravity center -extent 128x128  *.jpg


#Download missing thumbnails
require 'open-uri'

Product.find_each do |p|
filename = "thumbnails/#{p.category}/#{p.shopstyle_id}.jpg"

if not File.file?(filename)
gets()

if not File.directory?("thumbnails/#{p.category}")
Dir.mkdir("thumbnails/#{p.category}")
end

open(filename, 'wb') do |file|
file << open(p.thumbnail).read
end

end

end


Dir.new('.').each {|file| 
	if file[-4..-1] == ".jpg"
		#If this is an actual number
		id = file[0..-5]
		if id.to_i != 0

}
end


#Stratified sampling script
require 'json'
require 'open-uri'
require 'csv'

def extract(products)
products.each do |product|
p = Product.new(name: product["name"], category: product["category"], unbranded_name: product["unbrandedName"],retailer: product["retailer"], currency: product["currency"], price: product["price"], brand: product["brand"], description: product["description"], img: product["image"]["sizes"]["Original"]["url"], thumbnail: product["image"]["sizes"]["IPhoneSmall"]["url"], raw_xml: product.to_s)
if (not p.brand.nil? and p.brand[0] == '{')
p.brand = JSON.parse(p.brand.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
p.retailer = JSON.parse(p.retailer.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
p.category = JSON.parse(p.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["categories"][0]["name"]
p.shopstyle_id = JSON.parse(p.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["id"]

if p.raw_xml.include?("Men's")
p.gender_male = true
p.gender_female = false
elsif p.raw_xml.include?("Women's")
p.gender_female = true
p.gender_male = false
else
end

filename = "thumbnails/#{p.category}/#{p.shopstyle_id}.jpg"
if not File.file?(filename)
if not File.directory?("thumbnails/#{p.category}")
Dir.mkdir("thumbnails/#{p.category}")
end
open(filename, 'wb') do |file|
file << open(p.thumbnail).read
p.save
end

end
end
end
end

[['shirts', 'shirts'], ['formal shirts', 'formal shirts'], ['blazers', 'blazers'], 
['jackets', 'jackets'], ['jackets', 'jackets2'], ['mens', 'loungewear'],
['shirts', 'polos'], ['sweaters', 'sweaters'], ['tees', 't-shirts']].each do |input|

name = input[0]
filename = input[1]
stratified_sampling = CSV.read("stratified/#{filename}.csv")

styles = stratified_sampling.collect{|row| row[0]}.compact
details = stratified_sampling.collect{|row| row[1]}.compact
colors = stratified_sampling.collect{|row| row[2]}.compact

styles.each do |style|
colors.each do |color|

url = "http://api.shopstyle.com/api/v2/products?pid=uid5201-35972399-51&fts=+mens+#{name}+#{style}+#{color}&limit=50"
begin
products = JSON.parse(open(url).read())["products"]
extract(products)
rescue Exception => e
end

end
end

details.each do |style|
url = "http://api.shopstyle.com/api/v2/products?pid=uid5201-35972399-51&fts=+mens+#{name}+#{details}&limit=50"
begin
products = JSON.parse(open(url).read())["products"]
extract(products)
rescue Exception => e
end

end
end

#UPDATE scipt
require 'json'
require 'open-uri'

url = "http://api.shopstyle.com/api/v2/colors?pid=uid5201-35972399-51"

keywords = ["rugby shirt", "henley shirt", "kurta shirt",
"collared shirt", "ruffled shirt", "kimono", "tunic", "camo", "pleated", "printed", "shorts",
"cargo shorts", "chinos", "dandy", "drop crotch", "pinstripe", "printed", "joggers", "khakis",
"buffalo_check", "florals", "liberty print", "hawaiian", "polka dots", "chambrey",
	"gingham", "tattersall", "paisley","western_check", "derby shoes", "loafer", "oxford shoes", 
	"chelsea boots", "monk strap shoes", "brouge", "desert shoes", "boat shoes", "cowboy boots", 
	"longwings", "wingtips", "wholecuts", 	"high tops", "low tops", "chukka"]

keywords.each do |keyword|
10.times do |i|
offset = i*50 
url = "http://api.shopstyle.com/api/v2/products?pid=uid5201-35972399-51&fts=+mens+#{keyword}&offset=#{offset}&limit=50"
products = JSON.parse(open(url).read())["products"]

products.each do |product|
p = Product.new(name: product["name"], category: product["category"], unbranded_name: product["unbrandedName"],retailer: product["retailer"], currency: product["currency"], price: product["price"], brand: product["brand"], description: product["description"], img: product["image"]["sizes"]["Original"]["url"], thumbnail: product["image"]["sizes"]["IPhoneSmall"]["url"], raw_xml: product.to_s)
if (not p.brand.nil? and p.brand[0] == '{')
p.brand = JSON.parse(p.brand.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
p.retailer = JSON.parse(p.retailer.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["name"]
p.category = JSON.parse(p.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["categories"][0]["name"]
p.shopstyle_id = JSON.parse(p.raw_xml.gsub(%r{\ }, '').gsub(%r{=>}, ':'))["id"]

if p.raw_xml.include?("Men's")
p.gender_male = true
p.gender_female = false
elsif p.raw_xml.include?("Women's")
p.gender_female = true
p.gender_male = false
else
end

filename = "thumbnails/#{p.category}/#{p.shopstyle_id}.jpg"
if not File.file?(filename)
if not File.directory?("thumbnails/#{p.category}")
Dir.mkdir("thumbnails/#{p.category}")
end
open(filename, 'wb') do |file|
file << open(p.thumbnail).read
p.save
end
end
end
end
end
end