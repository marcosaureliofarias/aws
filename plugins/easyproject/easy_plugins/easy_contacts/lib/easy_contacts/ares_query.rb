module EasyContacts
  class AresQuery

    attr_reader :obchodni_firma, :okres, :obec, :cast_obce, :mestska_cast, :ulice,
                :cp, :co, :psc, :kod_statu, :stat, :kod_statu_iso

    ARES_QUERY_URL = "http://wwwinfo.mfcr.cz/cgi-bin/ares/darv_std.cgi"
    # http://wwwinfo.mfcr.cz/ares/ares_xml_standard.html.en
    # http://wwwinfo.mfcr.cz/ares/ares_xml_standard.html.cz

    def initialize(reg_no)
      @reg_no = reg_no
    end

    def query
      params = { ico: @reg_no.to_s, max_pocet: 1, czk: "utf" }
      url = ARES_QUERY_URL + '?' + URI.encode_www_form(params)
      doc = Nokogiri::XML(open(url))
      res = {}
      if entry = doc.xpath("/are:Ares_odpovedi/are:Odpoved/are:Zaznam").first
        res[:obchodni_firma] = @obchodni_firma = parse_entry_path(entry, "are:Obchodni_firma")
        res[:okres] = @okres = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:Nazev_okresu")
        res[:obec] = @obec = parse_entry_path( entry, "are:Identifikace/are:Adresa_ARES/dtt:Nazev_obce")
        res[:cast_obce] = @cast_obce = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:Nazev_casti_obce")
        res[:mestska_cast] = @mestska_cast = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:Nazev_mestske_casti")
        res[:ulice] = @ulice = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:Nazev_ulice")
        res[:cp] = @cp = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:Cislo_domovni")
        res[:co] = @co = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:Cislo_orientacni")
        res[:psc] = @psc = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:PSC")
        res[:kod_statu] = @kod_statu = parse_entry_path(entry, "are:Identifikace/are:Adresa_ARES/dtt:Kod_statu")
        if @kod_statu == "203"
          res[:kod_statu_iso] = @kod_statu_iso = "CZ"
          res[:kod_statu_alpha3] = @kod_statu_alpha3 = "CZE"
        end
      end
      res
    end

    def parse_entry_path(entry, path)
      res = entry.xpath(path)
      res.length > 0 ? res.first.text : nil
    end

  end
end
