require 'cgi'
require 'rexml/document'
include REXML

class FileParser

  #These are for soundtracks.  They are all in the soundtrack dir
  SOUNDTRACK=%r{/\(0 Soundtracks 0\)/([^/]+)/(?:(\d)\.)?(\d+) - (.+?) - (.+).mp3$}

  #Basic Albums
  ALBUM     =%r{/([^/]+)/(\d+) - (?:\(([^/]+)\) )?([^/]+?)(?: [EP])?/(?:(\d)\.)?(\d+) - (.+).mp3$}

  #Weird Albums
  LIVE_ALBUM=%r{/([^/]+)/Live - (.+)/(\d+) - (.+).mp3$}
  TRIBUTE_ALBUM=%r{/([^/]+)/Tribute - (.+)/(\d+) - (.+) - (.+).mp3$}
  OTHER_FOLDER=%r{/([^/]+)/Other/(.+).mp3$}

  IGNORE=%r{\.Trash|\(0 New 0\)}

  def initialize(path)
    @path = path
    return if ignored?
    @data = {}

    if SOUNDTRACK =~ path
      @data[:album] = "#{Regexp.last_match(1)} OST"
      @data[:disc] = Regexp.last_match(2)
      @data[:disctitle] = "Disc #{Regexp.last_match(2)}" unless Regexp.last_match(2).nil?
      @data[:track] = Regexp.last_match(3)
      @data[:artist] = Regexp.last_match(4)
      @data[:title] = Regexp.last_match(5)
    elsif ALBUM =~ path
      @data[:artist] = Regexp.last_match(1)
      @data[:year]  = Regexp.last_match(2)
      @data[:sort] = Regexp.last_match(3)
      @data[:album]  = Regexp.last_match(4)
      @data[:disc] = Regexp.last_match(5)
      @data[:disctitle] = "Disc #{Regexp.last_match(5)}" unless Regexp.last_match(5).nil?
      @data[:track]  = Regexp.last_match(6)
      @data[:title] = Regexp.last_match(7)
    elsif LIVE_ALBUM =~ path
      @data[:artist]  = Regexp.last_match(1)
      @data[:album]  = Regexp.last_match(2)
      @data[:track]  = Regexp.last_match(3)
      @data[:title] = Regexp.last_match(4)
      @data[:album]  = "#{@data[:album]} (Live)"
    elsif TRIBUTE_ALBUM =~ path
      @data[:album]  = Regexp.last_match(2)
      @data[:track]  = Regexp.last_match(3)
      @data[:artist]  = Regexp.last_match(4)
      @data[:title] = Regexp.last_match(5)
    elsif OTHER_FOLDER =~ path
      @data[:artist]  = Regexp.last_match(1)
      @data[:title] = Regexp.last_match(2)
    end
  end

  def matches?
    not ignored? and @data.length > 0
  end

  def ignored?
    IGNORE =~ @path
  end

  def artist
    normalize_artist(@data[:artist])
  end

  def year
    @data[:year]
  end

  def album
    @data[:album]
  end

  def sort
    @data[:sort]
  end

  def disc
    @data[:disc]
  end

  def disctitle
    @data[:disctitle]
  end

  def track
    @data[:track]
  end

  def title
    @data[:title]
  end

  def comment
    comments = []
    comments << sort unless sort.nil?
    comments << disctitle unless disctitle.nil?
    comments.join(" - ");
  end

  def normalize_artist(artist)
    # To convert from "Crystal Method, The" to "The Crystal Method"
    artist.gsub(/^(.*), (The|A|An)$/i, '\2 \1')

    # To convert from "The Crystal Method" to "Crystal Method, The"
    #artist.gsub(/^(The|A|An) (.*)$/i, '\2, \1')
  end

  def genre
    @data[:genre] = get_genre if @data[:genre].nil?
    @data[:genre]
  end

  def genre_display
    GENRES[genre]
  end
  

  GENRES = ["Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B", "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise", "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Showtunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock"]
  GENRE_MAP = {}
  IGNORE_GENRE_MAP = {}

  #Load the genres into memory
  GENRE_FILE=File.join(File.dirname(__FILE__),".genres.txt")
  if File.exists?(GENRE_FILE)
    File.open(GENRE_FILE, "r") do |infile|
      while (line = infile.gets)
        artist, genre = line.chomp.split(" -- ")
        GENRE_MAP[artist] = genre.to_i if not artist.nil?
      end
    end
  end

  def write_genres()
    #Write out the new GENRE file
    File.open(GENRE_FILE, 'w') do |f|
      GENRE_MAP.keys.sort.each do |artist|
        f.write("#{artist} -- #{GENRE_MAP[artist]}\n")
      end
    end
  end

  def show_hint(artist)
    xml = `curl "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&artist=#{CGI::escape(artist)}&api_key=922481d8d92827090692ee22124a71fd" 2>/dev/null`
    xmldoc = Document.new(xml)
    tags=[]
    xmldoc.elements.each("lfm/artist/tags/tag/name") do |e|
       tags << e.text
    end
    puts " (Tags from last.fm: #{tags.join(', ')})"
  end

  def get_genre()
    if GENRE_MAP.has_key?(artist)
      return GENRE_MAP[artist]
    elsif IGNORE_GENRE_MAP.has_key?(artist)
      return ""
    else
      puts "\nUnknown artist! What is the genre for \"#{artist}\"?\n"
      puts " (Looking at #{@path})\n"
      show_hint(artist)
      GENRE_MAP.values.uniq.sort.each do |v|
        puts "  #{v}. #{GENRES[v.to_i]}" if not v.nil?
      end
      puts "  99. List all"
      print "> "
      response = STDIN.gets.chomp
      if(response.empty?)
        IGNORE_GENRE_MAP[artist]=""
        return ""
      end

      response = response.to_i

      if(response == 99)
        puts "Select new genre for \"#{artist}\""
        GENRES.each_with_index do |genre, i|
          puts "    #{i}. #{genre}"
        end
        print "  > "
        response = STDIN.gets.chomp.to_i
      end

      if(response < GENRES.length)
          GENRE_MAP[artist] = response
          write_genres
          return response
      end
      
      puts "Invalid entry!"
      return get_genre(artist)
    end
  end

end

