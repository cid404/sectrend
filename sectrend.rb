require 'open-uri'
require 'nokogiri'
require 'date'
require 'twitter'

SLEEPER = 1800

def login
  #Twitter.configure do |config|
  # config.consumer_key = "xxx"
  # config.consumer_secret = "xxx"
  # config.oauth_token = "xxx"
  # config.oauth_token_secret = "xxx"
  #end
  ##above should be filled out, or import another file with the above content like below
  eval(IO.read('twitter_login'))
end

def find_ids(h)
  list = []
  h.each_pair do |key,value|
    begin
      next unless Twitter.user?(key) && !Twitter.user(key).protected
      timeline = Twitter.user_timeline(key,{:count => 100})
      value.each do |v|
        found = false
        timeline.each do |twit|
          if twit.full_text.include?(v[0,40])
            list << twit.id
            puts "Found! #{key}, #{v}"
            found = true
            break
          end
        end
        puts "Not found!  #{key}, #{v}" unless found
      end
    rescue Twitter::Error => e
      puts "ERROR!", e.message
    rescue Zlib::GzipFile::Error
      puts "Ahoy, I'm a Twitter gem bug, just ignore me  >_<"
    end
  end
  list
end

def retweet_all(list)
  list.each do |tweet|
    begin
      Twitter.retweet(tweet)
    rescue Exception => e
      if e.is_a?(Twitter::Error::Forbidden)
        puts 'Can\'t retweet the same thing'
      else
        puts e.message
        puts e.class
      end
    end
  end
end

def get_trends
  ret = {}
  doc = Nokogiri::XML(open('http://talkback.volvent.org/rss/trending-today.xml'))
  doc.xpath('//item').each do |e|
    d=DateTime.parse(e.xpath('pubDate').text)
    if !@tab.include?(d)
      #puts "#{e.xpath('title').text} | #{Nokogiri::HTML(e.xpath('description').text).text} | #{e.xpath('pubDate').text}"
      name = e.xpath('title').text.split[-1]
      ret[name] = [] if ret[name].nil?
      ret[name] << Nokogiri::HTML(e.xpath('description').text).text
      @tab << d
    end
  end
  @tab.drop(50) if @tab.size>200
  ret
end

def run
  @tab=[]
  login
  while true
    begin
      h = get_trends
      list = find_ids(h)
      retweet_all(list)
      puts 'Sleeping...'
    rescue Errno::ETIMEDOUT
      puts 'Timeout!'
    end
    sleep(SLEEPER)+rand(100)
  end
end

run
