class ReportPdf
  include Prawn::View
  include PdfUtils
  include Sanitizer

  def initialize(center, score_scheme, language)
    super()
    @center = center
    @score_scheme = score_scheme
    @language = language
    register_fonts
    font 'PT Sans'
    font_size 12
    default_leading 5
    content
    number_odd_pages
    number_even_pages
  end

  private

  def content
    page_one
    start_new_page(margin: 45)
    page_two
    start_new_page
    page_three
    start_new_page
    domain_data
    center_report
    start_new_page
    red_flag_data
    domain_one
    start_new_page
    domain_two
    start_new_page
    domain_three
    start_new_page
    domain_four
    start_new_page
    domain_five
    start_new_page
    domain_six
    start_new_page
    domain_level_feedback
    start_new_page
    additional_feedback
    start_new_page
    comparison_chart
  end

  def localize_text(key)
    I18n.t("report.#{key}", locale: @language)
  end

  def page_one
    image "#{Rails.root}/app/pdfs/images/mother_holding_child.png", fit: [535, 620], position: :center, at: [0, 730]
    image "#{Rails.root}/app/pdfs/images/sponsors.png", fit: [535, 100], position: :center, at: [100, 150]
    center_name_box = Prawn::Text::Box.new("<font size='14'><b><color rgb='FFFFFF'>#{@center.name}</color></b></font>",
                                           at: [bounds.width - (bounds.width * 0.85), bounds.top - 20],
                                           width: (bounds.width * 0.85) - 20, inline_format: true, align: :right, document: self)
    center_name_box.render(dry_run: true)
    height = center_name_box.height
    text_box "<font size='14'><b><color rgb='FFFFFF'>#{@center.name}</color></b></font>",
             at: [bounds.width - (bounds.width * 0.85), bounds.top - 20], width: (bounds.width * 0.85) - 20, inline_format: true, align: :right
    date = DateTime.now
    month = "month_#{date.month}"
    text_box "<font size='14'><b><color rgb='FFFFFF'>#{localize_text(month)} #{date.year}</color></b></font>",
             at: [bounds.width - (bounds.width * 0.85), bounds.top - 25 - height], width: (bounds.width * 0.85) - 20, inline_format: true, align: :right
    font('Avenir Next Condensed') do
      text_box "<font size='36'><b><color rgb='FFFFFF'>#{localize_text('p1_national')}</color></b></font>",
               at: [bounds.width - (bounds.width * 0.85), cursor - 370], width: (bounds.width * 0.85) - 20, inline_format: true, align: :right
      text_box "<font size='36'><b><color rgb='FFFFFF'>#{localize_text('p1_quality')}</color></b></font>",
               at: [bounds.width - (bounds.width * 0.85), cursor - 405], width: (bounds.width * 0.85) - 20, inline_format: true, align: :right
    end
  end

  def page_two
    font('Avenir Next Condensed') do
      text "<font size='36'><b>#{localize_text('p2_national')}</b></font>", inline_format: true, color: '2F642F', align: :left
      text "<font size='36'><b>#{localize_text('p2_quality')}</b></font>", inline_format: true, color: '2F642F', align: :left
    end
    text localize_text('p2_thanks')
    move_down 10
    text localize_text('p2_partnerships'), inline_format: true
    move_down 10
    text localize_text('p2_report')
    move_down 10
    text localize_text('p2_interpretation')
    move_down 10
    text localize_text('p2_appreciation')
  end

  def page_header_36(key)
    font('Avenir Next Condensed') do
      text "<font size='36'><b>#{localize_text(key)}</b></font>", inline_format: true, color: '2F642F'
    end
  end

  def page_three
    page_header_36('p3_usage')
    text localize_text('p3_report')
    move_down 10
    text localize_text('p3_overview')
    move_down 10
    text localize_text('p3_feedback'), inline_format: true
    move_down 10
    text localize_text('p3_additional'), inline_format: true
    move_down 10
    text localize_text('p3_red_flags')
    move_down 10
    text localize_text('p3_note')
    move_down 10
    text localize_text('p3_recommendations')
    move_down 10
    text localize_text('p3_review')
  end

  def center_details(label, response)
    [{ text: localize_text(label), styles: [:bold], color: '2F642F' }, { text: response }]
  end

  def center_report
    page_header_36('p4_report')
    css = @center.survey_scores.where(score_scheme_id: @score_scheme.id)
    contact = @center.contact(css)
    contact.gsub! /"/, ''
    formatted_text center_details('p4_center', @center.name)
    move_down 10
    formatted_text center_details('p4_director', contact)
    move_down 10
    formatted_text center_details('p4_representative', contact)
    move_down 10
    formatted_text center_details('p4_date', @center.interview_date(css))
    move_down 10
    formatted_text center_details('p4_interview', @center.interview?(css, @score_scheme, @language)) + center_details('p4_observation', @center.observation?(css, @score_scheme, @language))
    move_down 10
    lw = line_width
    sc = stroke_color
    line_width(2)
    stroke_color('2F642F')
    stroke_horizontal_rule
    move_down 5
    stroke_horizontal_rule
    line_width(lw)
    stroke_color(sc)
    move_down 10

    domain_title(localize_text('p4_snapshot'))

    d_scores = [@scores[@center.identifier]['Score']]
    labels = { 0 => localize_text('p4_label') }
    nat_scores = [@nat_avg_scores['Score']]
    cda = []
    cda = [[@private_scores['Score']], [@public_scores['Score']]] if is_cda?
    gruff_graph('0', d_scores.map { |v| v == '' ? 0 : v }, nat_scores.map { |v| v == '' ? 0 : v }, labels, cda)

    image "#{Rails.root}/files/reports/#{@center.identifier}-0-#{@language}.png", position: :center, fit: [530, 350]
    move_down 10
    text "<font size='9'>#{localize_text("p4_#{@center.center_type}")}</font>", inline_format: true
  end

  def domain_data
    centers = @score_scheme.centers.where(center_type: @center.center_type)
    rows, nat_avg_row = Center.sheet_data(@score_scheme, centers)
    header = Center.sheet_header(@score_scheme)
    @scores = {}
    rows.each do |row|
      center_domain_data = {}
      row.each_with_index do |item, index|
        center_domain_data[header[index]] = item
      end
      @scores[row[0]] = center_domain_data
    end
    @nat_avg_scores = {}
    nat_avg_row.each_with_index do |item, index|
      @nat_avg_scores[header[index]] = item
    end
    if is_cda?
      public = @score_scheme.centers.where('center_type = ? and administration = ?', 'CDA', 'Publico')
      pub_rows, public_nat_avg_row = Center.sheet_data(@score_scheme, public)
      @public_scores = {}
      public_nat_avg_row.each_with_index do |item, index|
        @public_scores[header[index]] = item
      end
      private = @score_scheme.centers.where('center_type = ? and administration = ?', 'CDA', 'Privado')
      pri_rows, private_nat_avg_row = Center.sheet_data(@score_scheme, private)
      @private_scores = {}
      private_nat_avg_row.each_with_index do |item, index|
        @private_scores[header[index]] = item
      end
    end
  end

  def red_flag_data
    css = @center.survey_scores.where(score_scheme_id: @score_scheme.id)
    responses = @center.responses(css)
    @red_flag_responses = {}
    @score_scheme.domains.each do |domain|
      domain_red_flags = {}
      domain.subdomains.each do |subdomain|
        subdomain.score_units.each do |unit|
          unit.score_unit_questions.each do |suq|
            suq_responses = responses.where(question_identifier: suq.question_identifier)
            suq_responses.each do |response|
              domain_red_flags[response.question_identifier] = response if response.is_red_flag?(@score_scheme)
            end
          end
        end
      end
      @red_flag_responses[domain.title] = domain_red_flags.values
    end
  end

  def domain_title(title)
    font('Avenir Next Condensed') do
      text "<font size='20'><b>#{title}</b></font>", inline_format: true, color: '2F642F'
    end
    move_down 10
  end

  # CDA is residential
  def is_cda?
    @center.center_type == 'CDA'
  end

  def domain_table(title)
    ds = @scores[@center.identifier][title]
    ds = ds.round(2) if ds != ''
    if is_cda?
      table [
        ['', "<b>#{@center.name}</b>", "<b>#{I18n.t('report.public', type: @center.center_type, locale: @language)}</b>",
         "<b>#{I18n.t('report.private', type: @center.center_type, locale: @language)}</b>",
         "<b>#{I18n.t('report.both', type: @center.center_type, locale: @language)}</b>"],
        ["<b>#{localize_text('domain_scores')}</b>", ds, @public_scores[title], @private_scores[title], @nat_avg_scores[title]]
      ], position: :center, cell_style: { align: :center, inline_format: true }
    else
      table [
        ['', "<b>#{@center.name}</b>", "<b>#{I18n.t('report.national', type: @center.center_type, locale: @language)}</b>"],
        ["<b>#{localize_text('domain_scores')}</b>", ds, @nat_avg_scores[title]]
      ], position: :center, cell_style: { align: :center, inline_format: true }
    end
    move_down 10
  end

  def ordinal(n)
    return 'th' if [11, 12, 13].include?(n)

    case n % 10
    when 1
      'st'
    when 2
      'nd'
    when 3
      'rd'
    else
      'th'
    end
  end

  def score_rank(title)
    ds = @scores[@center.identifier][title]
    domain_scores = []
    array = @scores
    if is_cda?
      if @center.administration == 'Privado'
        @scores.each do |identifier, _sc|
          ctr = @score_scheme.centers.find_by(identifier: identifier)
          array.delete(identifier) if ctr.administration != 'Privado'
        end
      else
        @scores.each do |identifier, _sc|
          ctr = @score_scheme.centers.find_by(identifier: identifier)
          array.delete(identifier) if ctr.administration != 'Publico'
        end
      end
    end
    array.each do |_identifier, sc|
      domain_scores << sc[title]
    end
    less = domain_scores.select { |score| score <= ds }
    rank = ((less.size.to_f / domain_scores.size.to_f) * 100).round
  end

  def domain_score_graph(title, feedback)
    move_down 10
    ds = @scores[@center.identifier][title]
    ds = ds.round(2) if ds != ''
    rank = score_rank(title)
    text I18n.t('report.d1_score', score: ds, percentile: rank, sup: ordinal(rank), locale: @language), inline_format: true
    move_down 20
    font('Avenir Next Condensed') do
      text "<font size='16'><b>#{feedback}</b></font>", inline_format: true, color: '767171'
    end
    move_down 10
    image "#{Rails.root}/files/reports/#{@center.identifier}-#{title}-#{@language}.png", position: :center, fit: [530, 350]
    move_down 5
    text "<font size='9'>#{localize_text('null_score')}</font>", inline_format: true
    move_down 10
  end

  def doing_well(lowest, message)
    if lowest[1] >= 3.01
      move_down 10
      text message
    end
  end

  def highest_scoring_subdomain(highest, d_scores, name)
    max_array = Hash[d_scores.select { |_k, v| v == highest[1] }]
    if max_array.size == 1
      sd = @score_scheme.subdomains.find_by(title: highest[0].to_s)
      tsd_title = @score_scheme.instrument.language == @language ? sd.name : full_sanitizer.sanitize(sd.translated_name(@language))
      title = "#{highest[0]} #{tsd_title}"
    else
      sds = []
      max_array.each do |k, _v|
        sd = @score_scheme.subdomains.find_by(title: k.to_s)
        tsd_title = @score_scheme.instrument.language == @language ? sd.name : full_sanitizer.sanitize(sd.translated_name(@language))
        sds << "#{k} #{tsd_title}"
      end
      title = sds.join(', ')
    end
    text I18n.t('report.d_highest', name: name, title: title, count: max_array.size, highest: highest[1].round(2), locale: @language), inline_format: true
    move_down 5
    indent(15) do
      max_array.each do |k, _v|
        text localize_text(high_low_score_key(k.to_s, 'high'))
        move_down 5
      end
    end
  end

  def high_low_score_key(sd_title, high_low)
    prefix = 'h'
    prefix = 'l' if high_low == 'low'
    if ['2.6', '3.5', '4.1', '4.6', '5.1', '5.2', '5.3', '5.4', '5.5'].include?(sd_title)
      sd_title[1] = '_'
      is_cda? ? "#{prefix}_#{sd_title}_r" : "#{prefix}_#{sd_title}_n"
    else
      sd_title[1] = '_'
      "#{prefix}_#{sd_title}"
    end
  end

  def low_scoring_subdomains(lowest, d_scores)
    if lowest[1] < 3.01
      low_quality
      d_scores.each do |title, score|
        bounds.move_past_bottom if y < 75
        low_score(title.to_s, score) if score != '' && score < 3.01
      end
    end
  end

  def low_quality
    move_down 10
    text localize_text('d1_low_quality'), inline_format: true
    move_down 10
  end

  def low_score(title, score)
    sd = @score_scheme.subdomains.find_by(title: title)
    name = @score_scheme.instrument.language == @language ? sd.name : full_sanitizer.sanitize(sd.translated_name(@language))
    text I18n.t('report.d_low_score', name: "#{title} #{name}", score: score.round(2), locale: @language), inline_format: true
    move_down 5
    indent(15) do
      text localize_text(high_low_score_key(title, 'low'))
    end
    move_down 10
  end

  def rn
    is_cda? ? 'r' : 'n'
  end

  def residential_only
    %w[aac7 cap2 cap3 csm1 csm3 cts2 cts3 cts4 cts5 els5 els6 hlt1 ide5 ide8 sts2]
  end

  def non_residential_only
    %w[cts4 cts6]
  end

  def red_flag_domain
    { 'aac4': '4', 'aac7': '5', 'bcu5': '2', 'bra1': '5', 'bra2': '6', 'cab2': '4', 'cab3': '4', 'cap2': '1', 'cap3': '1',
      'cga5': '4', 'cmc3': '6', 'csm1': '3', 'csm3': '3', 'css1': '3', 'css3': '3', 'css5': '3', 'css6': '1', 'css7': '2',
      'css10': '2', 'css11': '2', 'cta3': '3', 'cts2': '3', 'cts3': '3', 'cts4': '3', 'cts5': '3', 'cts6': '3', 'cts7': '4',
      'cts8': '4', 'ctu3': '2', 'ctu4': '2', 'dca2': '6', 'els5': '2',
      'els6': '2', 'els7': '2', 'eta2': '6', 'fom3': '3', 'fom6': '3', 'fom8': '3', 'fom10': '3', 'fpa3': '6', 'fpa4': '6',
      'hlt1': '2', 'hlt7': '2', 'hlt9': '2', 'hlt10': '2', 'ide5': '2', 'ide8': '2', 'ide15': '3', 'ide18': '2', 'idp1': '2',
      'ltc12': '3', 'nut2': '2', 'nut10': '2', 'ogh1': '2', 'ogh2': '2', 'rbi7': '3', 'rbi10': '3', 'rbi19': '3', 'rbo1': '4',
      'rbo4': '3', 'rbo5': '4', 'rbo6': '4', 'rcd9': '2', 'sap1': '2', 'sdm1': '4', 'sdm6': '1', 'sia8': '2', 'sla6': '6',
      'sot3': '1', 'sts2': '1', 'sts3': '1', 'vin6': '3', 'vis2_1': '3', 'vis2_2': '3', 'vnc3': '4', 'vol6': '3' }
  end

  def red_flag_description(str)
    bounds.move_past_bottom if y < 60
    fill_color 'F06A78'
    fill_circle [bounds.left, cursor - 9], 2
    fill_color '000000'
    indent(7) do
      text "<b>#{str}</b>", inline_format: true
    end
    move_down 5
  end

  def red_flag_recommendation(rec)
    indent(15) do
      text rec
    end
    move_down 5
  end

  def red_flag_other_domains(response, domain)
    set = Set[]
    score_units = @score_scheme.score_units.where(title: response.question_identifier)
    score_units.each do |unit|
      set << localize_text("d#{unit.subdomain.domain.title}_title")
    end
    set.delete(localize_text("d#{domain.title}_title"))
    indent(15) do
      text I18n.t('report.other_domains', domains: set.to_a.join(', '), locale: @language), inline_format: true unless set.empty?
    end
    move_down 5
  end

  def red_flags(name, title)
    move_down 10
    bounds.move_past_bottom if y < 60
    font('Avenir Next Condensed') do
      text "<font size='16'><b>#{name}</b></font>", inline_format: true, color: '767171'
    end
    domain = @score_scheme.domains.find_by(title: title)
    domain_red_flag_responses = @red_flag_responses[domain.title]
    no_red_flags = true
    some_red_flags = false
    set = Set[]
    domain_red_flag_responses.each do |response|
      iq = response.instrument_question
      identifiers = response.red_flag_response_options(@score_scheme).pluck(:identifier)
      all_flags = response.red_flags.where(score_scheme_id: @score_scheme.id).where(option_identifier: identifiers).group_by(&:instruction_id)
      flags = []
      all_flags.values.each do |duplicates|
        flags << duplicates.shift
      end
      next if flags.empty?

      other_title = red_flag_domain[response.question_identifier.to_sym]
      if other_title != title
        set << other_title
        some_red_flags = true
        next
      end
      flags.each do |flag|
        no_red_flags = false
        if %w[aac4 css5 css7 cts2 cts5 els5 els6 els7 fom8 ltc12 rbi7 rbi19 rbo5 sdm1 sla6 vin6 vis2_1 vis2_2 vnc3 vol6].include?(response.question_identifier)
          option = iq.hashed_options[flag.option_identifier]
          index = iq.non_special_options.index(option)
          letter = iq.letters[index]
          if %w[aac4 els7 rbi7 rbi19 sdm1 vis2_1 vis2_2].include?(response.question_identifier)
            red_flag_description(localize_text("#{response.question_identifier}_#{letter}_d"))
            red_flag_recommendation(localize_text("#{rn}_#{response.question_identifier}_#{letter}"))
          else
            red_flag_description(localize_text("#{response.question_identifier}_#{letter}_d"))
            red_flag_recommendation(localize_text("#{response.question_identifier}_#{letter}"))
          end
        elsif %w[bcu5 bra2 els7 ide15 ide18 nut2 nut10].include?(response.question_identifier)
          red_flag_description(localize_text("#{response.question_identifier}_d"))
          red_flag_recommendation(localize_text("#{rn}_#{response.question_identifier}"))
        else
          red_flag_description(localize_text("#{response.question_identifier}_d"))
          red_flag_recommendation(localize_text(response.question_identifier))
        end
      end
      red_flag_other_domains(response, domain)
    end
    text localize_text('no_red_flags') if no_red_flags && !some_red_flags
    if some_red_flags
      other_domains = @score_scheme.domains.where(title: set.to_a)
      titles = []
      other_domains.each do |dom|
        titles << localize_text("d#{dom.title}_title")
      end
      text I18n.t('report.some_red_flags', domains: titles.join(', '), locale: @language), inline_format: true unless titles.empty?
    end
    move_down 20
  end

  def cleaned_scores(d_scores)
    d_scores_clean = d_scores.reject { |_k, v| v == '' }
    lowest = d_scores_clean.min_by { |_k, v| v }
    highest = d_scores_clean.max_by { |_k, v| v }
    [lowest, highest]
  end

  def gruff_graph(title, d_scores, nat_scores, labels, cdas)
    g = Gruff::Bar.new('1600x800')
    g.title = localize_text("d#{title}_name") if title != '0'
    g.title = localize_text('p4_title') if title == '0'
    g.font = "#{Rails.root}/app/pdfs/fonts/PTSans-Regular.ttf"
    g.title_font_size = 14
    g.legend_font_size = 12
    g.marker_font_size = 10
    g.theme = {
      colors: ['#3e6232', '#9ab77d', '#6c994f'],
      marker_color: 'black',
      font_color: 'black',
      background_colors: %w[#ffffff #ffffff]
    }
    g.labels = labels
    g.data(@center.name.to_sym, d_scores)
    if is_cda?
      if @center.administration == 'Privado'
        g.data(I18n.t('report.private', type: @center.center_type, locale: @language).to_sym, cdas[0])
      else
        g.data(I18n.t('report.public', type: @center.center_type, locale: @language).to_sym, cdas[1])
      end
    end
    g.data(I18n.t('report.nationals', type: @center.center_type, locale: @language).to_sym, nat_scores)
    g.show_labels_for_bar_values = true
    g.minimum_value = 0
    g.maximum_value = 7
    g.legend_at_bottom = true
    img = "#{Rails.root}/files/reports/#{@center.identifier}-#{title}-#{@language}"
    g.write("#{img}.png")
    graph = Magick::Image.read("#{img}.png").first
    cropped = graph.crop(50, 45, 1520, 720)
    background = Magick::Image.new(1850, 720)
    result = background.composite(cropped, Magick::NorthWestGravity, Magick::OverCompositeOp)
    draw = Magick::Draw.new
    low_text = @language == 'en' ? '1-3: low-quality care' : '1-3: baja calidad'
    good_text = @language == 'en' ? '3-5: good-quality care' : '3-5: mediana calidad'
    high_text = @language == 'en' ? '5-7: high-quality care' : '5-7: alta calidad'
    draw.annotate(result, 330, 40, 1520, 460, low_text) do |options|
      options.pointsize = 25
      options.font = 'PT Sans'
    end
    draw.annotate(result, 330, 40, 1520, 325, good_text) do |options|
      options.pointsize = 25
      options.font = 'PT Sans'
    end
    draw.annotate(result, 330, 40, 1520, 185, high_text) do |options|
      options.pointsize = 25
      options.font = 'PT Sans'
    end
    result.write("#{img}.png")
  end

  def domain_one
    domain_title(localize_text('d1_title'))
    domain_table('1')
    text localize_text('d1_admin'), inline_format: true
    d_scores = {
      '1.1': @scores[@center.identifier]['1.1'], '1.2': @scores[@center.identifier]['1.2'],
      '1.3': @scores[@center.identifier]['1.3'], '1.4': @scores[@center.identifier]['1.4']
    }
    nat_scores = [@nat_avg_scores['1.1'], @nat_avg_scores['1.2'], @nat_avg_scores['1.3'], @nat_avg_scores['1.4']]
    sd_alt_names = @score_scheme.domains.find_by(title: '1').subdomains.map { |sd| full_sanitizer.sanitize(sd.alt_name(@language)) }
    labels = { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2], 3 => sd_alt_names[3] }
    cda = []
    if is_cda?
      cda = [[@private_scores['1.1'], @private_scores['1.2'], @private_scores['1.3'], @private_scores['1.4']],
             [@public_scores['1.1'], @public_scores['1.2'], @public_scores['1.3'], @public_scores['1.4']]]
    end
    gruff_graph('1', d_scores.values.map { |v| v == '' ? 0 : v }, nat_scores.map { |v| v == '' ? 0 : v }, labels, cda)
    domain_score_graph('1', localize_text('d1_feedback'))
    lowest, highest = cleaned_scores(d_scores)
    highest_scoring_subdomain(highest, d_scores, localize_text('d1_name'))
    doing_well(lowest, localize_text('d1_all_well'))
    low_scoring_subdomains(lowest, d_scores)
    red_flags(localize_text('d1_red_flags'), '1')
  end

  def domain_two
    domain_title(localize_text('d2_title'))
    domain_table('2')
    text localize_text('d2_admin'), inline_format: true
    d_scores = if is_cda?
                 {
                   '2.1': @scores[@center.identifier]['2.1'], '2.2': @scores[@center.identifier]['2.2'],
                   '2.3': @scores[@center.identifier]['2.3'], '2.4': @scores[@center.identifier]['2.4'],
                   '2.5': @scores[@center.identifier]['2.5'], '2.6': @scores[@center.identifier]['2.6'],
                   '2.7': @scores[@center.identifier]['2.7'], '2.8': @scores[@center.identifier]['2.8'],
                   '2.9': @scores[@center.identifier]['2.9']
                 }
               else
                 {
                   '2.1': @scores[@center.identifier]['2.1'], '2.2': @scores[@center.identifier]['2.2'],
                   '2.3': @scores[@center.identifier]['2.3'], '2.4': @scores[@center.identifier]['2.4'],
                   '2.5': @scores[@center.identifier]['2.5'], '2.6': @scores[@center.identifier]['2.6'],
                   '2.8': @scores[@center.identifier]['2.8'], '2.9': @scores[@center.identifier]['2.9']
                 }
               end
    nat_scores = if is_cda?
                   [@nat_avg_scores['2.1'], @nat_avg_scores['2.2'], @nat_avg_scores['2.3'], @nat_avg_scores['2.4'],
                    @nat_avg_scores['2.5'], @nat_avg_scores['2.6'], @nat_avg_scores['2.7'], @nat_avg_scores['2.8'],
                    @nat_avg_scores['2.9']]
                 else
                   [@nat_avg_scores['2.1'], @nat_avg_scores['2.2'], @nat_avg_scores['2.3'], @nat_avg_scores['2.4'],
                    @nat_avg_scores['2.5'], @nat_avg_scores['2.6'], @nat_avg_scores['2.8'], @nat_avg_scores['2.9']]
                 end
    sd_alt_names = @score_scheme.domains.find_by(title: '2').subdomains.map { |sd| full_sanitizer.sanitize(sd.alt_name(@language)) }
    labels = if is_cda?
               { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2], 3 => sd_alt_names[3],
                 4 => sd_alt_names[4], 5 => sd_alt_names[5], 6 => sd_alt_names[6], 7 => sd_alt_names[7], 8 => sd_alt_names[8] }
             else
               { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2], 3 => sd_alt_names[3],
                 4 => sd_alt_names[4], 5 => sd_alt_names[5], 6 => sd_alt_names[7], 7 => sd_alt_names[8] }
             end
    cda = []
    if is_cda?
      cda = [[@private_scores['2.1'], @private_scores['2.2'], @private_scores['2.3'], @private_scores['2.4'],
              @private_scores['2.5'], @private_scores['2.6'], @private_scores['2.7'], @private_scores['2.8'],
              @private_scores['2.9']],
             [@public_scores['2.1'], @public_scores['2.2'], @public_scores['2.3'], @public_scores['2.4'],
              @public_scores['2.5'], @public_scores['2.6'], @public_scores['2.7'], @public_scores['2.8'],
              @public_scores['2.9']]]
    end
    gruff_graph('2', d_scores.values.map { |v| v == '' ? 0 : v }, nat_scores.map { |v| v == '' ? 0 : v }, labels, cda)
    domain_score_graph('2', localize_text('d2_feedback'))
    lowest, highest = cleaned_scores(d_scores)
    highest_scoring_subdomain(highest, d_scores, localize_text('d2_name'))
    doing_well(lowest, localize_text('d2_all_well'))
    low_scoring_subdomains(lowest, d_scores)
    red_flags(localize_text('d2_red_flags'), '2')
  end

  def domain_three
    domain_title(localize_text('d3_title'))
    domain_table('3')
    text localize_text('d3_admin'), inline_format: true
    d_scores = if is_cda?
                 {
                   '3.1': @scores[@center.identifier]['3.1'], '3.2': @scores[@center.identifier]['3.2'],
                   '3.3': @scores[@center.identifier]['3.3'], '3.4': @scores[@center.identifier]['3.4'],
                   '3.5': @scores[@center.identifier]['3.5'], '3.6': @scores[@center.identifier]['3.6']
                 }
               else
                 {
                   '3.1': @scores[@center.identifier]['3.1'], '3.2': @scores[@center.identifier]['3.2'],
                   '3.3': @scores[@center.identifier]['3.3'], '3.4': @scores[@center.identifier]['3.4'],
                   '3.5': @scores[@center.identifier]['3.5']
                 }
               end
    nat_scores = if is_cda?
                   [@nat_avg_scores['3.1'], @nat_avg_scores['3.2'], @nat_avg_scores['3.3'], @nat_avg_scores['3.4'],
                    @nat_avg_scores['3.5'], @nat_avg_scores['3.6']]
                 else
                   [@nat_avg_scores['3.1'], @nat_avg_scores['3.2'], @nat_avg_scores['3.3'], @nat_avg_scores['3.4'],
                    @nat_avg_scores['3.5']]
                 end
    sd_alt_names = @score_scheme.domains.find_by(title: '3').subdomains.map { |sd| full_sanitizer.sanitize(sd.alt_name(@language)) }
    labels = if is_cda?
               { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2], 3 => sd_alt_names[3],
                 4 => sd_alt_names[4], 5 => sd_alt_names[5] }
             else
               { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2], 3 => sd_alt_names[3],
                 4 => sd_alt_names[4] }
             end
    cda = []
    if is_cda?
      cda = [[@private_scores['3.1'], @private_scores['3.2'], @private_scores['3.3'], @private_scores['3.4'],
              @private_scores['3.5'], @private_scores['3.6']],
             [@public_scores['3.1'], @public_scores['3.2'], @public_scores['3.3'], @public_scores['3.4'],
              @public_scores['3.5']]]
    end
    gruff_graph('3', d_scores.values.map { |v| v == '' ? 0 : v }, nat_scores.map { |v| v == '' ? 0 : v }, labels, cda)
    domain_score_graph('3', localize_text('d3_feedback'))
    lowest, highest = cleaned_scores(d_scores)
    highest_scoring_subdomain(highest, d_scores, localize_text('d3_name'))
    doing_well(lowest, localize_text('d3_all_well'))
    low_scoring_subdomains(lowest, d_scores)
    red_flags(localize_text('d3_red_flags'), '3')
  end

  def domain_four
    domain_title(localize_text('d4_title'))
    domain_table('4')
    text localize_text('d4_admin'), inline_format: true
    d_scores = {
      '4.1': @scores[@center.identifier]['4.1'], '4.2': @scores[@center.identifier]['4.2'],
      '4.3': @scores[@center.identifier]['4.3'], '4.4': @scores[@center.identifier]['4.4'],
      '4.5': @scores[@center.identifier]['4.5'], '4.6': @scores[@center.identifier]['4.6']
    }
    nat_scores = [@nat_avg_scores['4.1'], @nat_avg_scores['4.2'], @nat_avg_scores['4.3'], @nat_avg_scores['4.4'],
                  @nat_avg_scores['4.5'], @nat_avg_scores['4.6']]
    sd_alt_names = @score_scheme.domains.find_by(title: '4').subdomains.map { |sd| full_sanitizer.sanitize(sd.alt_name(@language)) }
    labels = { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2], 3 => sd_alt_names[3],
               4 => sd_alt_names[4], 5 => sd_alt_names[5] }
    cda = []
    if is_cda?
      cda = [[@private_scores['4.1'], @private_scores['4.2'], @private_scores['4.3'], @private_scores['4.4'],
              @private_scores['4.5'], @private_scores['4.6']],
             [@public_scores['4.1'], @public_scores['4.2'], @public_scores['4.3'], @public_scores['4.4'],
              @public_scores['4.5'], @public_scores['4.6']]]
    end
    gruff_graph('4', d_scores.values.map { |v| v == '' ? 0 : v }, nat_scores.map { |v| v == '' ? 0 : v }, labels, cda)
    domain_score_graph('4', localize_text('d4_feedback'))
    lowest, highest = cleaned_scores(d_scores)
    highest_scoring_subdomain(highest, d_scores, localize_text('d4_name'))
    doing_well(lowest, localize_text('d4_all_well'))
    low_scoring_subdomains(lowest, d_scores)
    red_flags(localize_text('d4_red_flags'), '4')
  end

  def domain_five
    domain_title(localize_text('d5_title'))
    domain_table('5')
    text localize_text('d5_admin'), inline_format: true
    d_scores = if is_cda?
                 {
                   '5.1': @scores[@center.identifier]['5.1'], '5.2': @scores[@center.identifier]['5.2'],
                   '5.3': @scores[@center.identifier]['5.3'], '5.4': @scores[@center.identifier]['5.4'],
                   '5.5': @scores[@center.identifier]['5.5'], '5.6': @scores[@center.identifier]['5.6'],
                   '5.7': @scores[@center.identifier]['5.7'], '5.8': @scores[@center.identifier]['5.8']
                 }
               else
                 {
                   '5.1': @scores[@center.identifier]['5.1'], '5.3': @scores[@center.identifier]['5.3'],
                   '5.4': @scores[@center.identifier]['5.4'], '5.5': @scores[@center.identifier]['5.5']
                 }
               end
    nat_scores = if is_cda?
                   [@nat_avg_scores['5.1'], @nat_avg_scores['5.2'], @nat_avg_scores['5.3'], @nat_avg_scores['5.4'],
                    @nat_avg_scores['5.5'], @nat_avg_scores['5.6'], @nat_avg_scores['5.7'], @nat_avg_scores['5.8']]
                 else
                   [@nat_avg_scores['5.1'], @nat_avg_scores['5.3'], @nat_avg_scores['5.4'], @nat_avg_scores['5.5']]
                 end
    sd_alt_names = @score_scheme.domains.find_by(title: '5').subdomains.map { |sd| full_sanitizer.sanitize(sd.alt_name(@language)) }
    labels = if is_cda?
               { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2], 3 => sd_alt_names[3],
                 4 => sd_alt_names[4], 5 => sd_alt_names[5], 6 => sd_alt_names[6], 7 => sd_alt_names[7] }
             else
               { 0 => sd_alt_names[0], 1 => sd_alt_names[2], 2 => sd_alt_names[3], 3 => sd_alt_names[4] }
             end
    cda = []
    if is_cda?
      cda = [[@private_scores['5.1'], @private_scores['5.2'], @private_scores['5.3'], @private_scores['5.4'],
              @private_scores['5.5'], @private_scores['5.6'], @private_scores['5.7'], @private_scores['5.8']],
             [@public_scores['5.1'], @public_scores['5.2'], @public_scores['5.3'], @public_scores['5.4'],
              @public_scores['5.5'], @public_scores['5.6'], @public_scores['5.7'], @public_scores['5.8']]]
    end
    gruff_graph('5', d_scores.values.map { |v| v == '' ? 0 : v }, nat_scores.map { |v| v == '' ? 0 : v }, labels, cda)
    domain_score_graph('5', localize_text('d5_feedback'))
    lowest, highest = cleaned_scores(d_scores)
    highest_scoring_subdomain(highest, d_scores, localize_text('d5_name'))
    doing_well(lowest, localize_text('d5_all_well'))
    low_scoring_subdomains(lowest, d_scores)
    red_flags(localize_text('d5_red_flags'), '5')
  end

  def domain_six
    domain_title(localize_text('d6_title'))
    domain_table('6')
    text localize_text('d6_admin'), inline_format: true
    d_scores = {
      '6.1': @scores[@center.identifier]['6.1'], '6.2': @scores[@center.identifier]['6.2'],
      '6.3': @scores[@center.identifier]['6.3']
    }
    nat_scores = [@nat_avg_scores['6.1'], @nat_avg_scores['6.2'], @nat_avg_scores['6.3']]
    sd_alt_names = @score_scheme.domains.find_by(title: '6').subdomains.map { |sd| full_sanitizer.sanitize(sd.alt_name(@language)) }
    labels = { 0 => sd_alt_names[0], 1 => sd_alt_names[1], 2 => sd_alt_names[2] }
    cda = []
    if is_cda?
      cda = [[@private_scores['6.1'], @private_scores['6.2'], @private_scores['6.3']],
             [@public_scores['6.1'], @public_scores['6.2'], @public_scores['6.3']]]
    end
    gruff_graph('6', d_scores.values.map { |v| v == '' ? 0 : v }, nat_scores.map { |v| v == '' ? 0 : v }, labels, cda)
    domain_score_graph('6', localize_text('d6_feedback'))
    lowest, highest = cleaned_scores(d_scores)
    highest_scoring_subdomain(highest, d_scores, localize_text('d6_name'))
    doing_well(lowest, localize_text('d6_all_well'))
    low_scoring_subdomains(lowest, d_scores)
    red_flags(localize_text('d6_red_flags'), '6')
  end

  def domain_level_feedback
    domain_title(localize_text('dl_feedback'))
    domain_one_feedback
    move_down 10
    domain_two_feedback
    move_down 10
    domain_three_feedback
    move_down 10
    domain_four_feedback
    move_down 10
    domain_five_feedback
    move_down 10
    domain_six_feedback
  end

  def domain_header(name)
    font('Avenir Next Condensed') do
      text "<font size='18'><b>#{name}</b></font>", inline_format: true, color: '767171'
    end
    move_down 5
  end

  def domain_one_feedback
    domain_header(localize_text('d1_title'))
    text localize_text('d1_overview')
    domain_feedback('1')
  end

  def domain_two_feedback
    domain_header(localize_text('d2_title'))
    text localize_text('d2_overview')
    domain_feedback('2')
  end

  def domain_three_feedback
    domain_header(localize_text('d3_title'))
    text localize_text('d3_overview')
    domain_feedback('3')
  end

  def domain_four_feedback
    domain_header(localize_text('d4_title'))
    text localize_text('d4_overview')
    domain_feedback('4')
  end

  def domain_five_feedback
    domain_header(localize_text('d5_title'))
    text localize_text('d5_overview')
    domain_feedback('5')
  end

  def domain_six_feedback
    domain_header(localize_text('d6_title'))
    text localize_text('d6_overview')
    domain_feedback('6')
  end

  def domain_feedback(title)
    ds = @scores[@center.identifier][title]
    ds = ds.round(2) if ds != ''
    move_down 10
    case ds
    when 1.0..3.0
      overview('low', title)
      inferior_quality(title)
    when 3.01..5.0
      overview('mid', title)
      mid_quality(title)
    when 5.01..7.0
      overview('high', title)
      high_quality(title)
    else
      text 'NO SCORE'
    end
  end

  def overview(key, title)
    text I18n.t("report.#{key}", name: localize_text("d#{title}_name"), locale: @language)
  end

  def bullet_points(range, prefix)
    move_down 10
    indent(20) do
      range.each do |index|
        bounds.move_past_bottom if y < 60
        stroke_rectangle [bounds.left, cursor - 5], 8, 8
        indent(23) do
          pad(1) { text localize_text("#{prefix}_#{index}") }
        end
      end
    end
  end

  def high_quality(title)
    case title
    when '1'
      bullet_points(1..5, 'd1_high')
    when '2'
      if is_cda?
        bullet_points(1..17, 'd2_high_res')
      else
        bullet_points(1..15, 'd2_high_non')
      end
    when '3'
      if is_cda?
        bullet_points(1..8, 'd3_high_res')
      else
        bullet_points(1..7, 'd3_high_non')
      end
    when '4'
      bullet_points(1..12, 'd4_high')
    when '5'
      if is_cda?
        bullet_points(1..17, 'd5_high_res')
      else
        bullet_points(1..6, 'd5_high_non')
      end
    when '6'
      bullet_points(1..8, 'd6_high')
    else
      text 'OUT OF RANGE'
    end
  end

  def mid_quality(title)
    case title
    when '1'
      bullet_points(1..7, 'd1_mid')
    when '2'
      if is_cda?
        bullet_points(1..14, 'd2_mid_res')
      else
        bullet_points(1..13, 'd2_mid_non')
      end
    when '3'
      if is_cda?
        bullet_points(1..7, 'd3_mid_res')
      else
        bullet_points(1..6, 'd3_mid_non')
      end
    when '4'
      bullet_points(1..14, 'd4_mid')
    when '5'
      if is_cda?
        bullet_points(1..15, 'd5_mid_res')
      else
        bullet_points(1..6, 'd5_mid_non')
      end
    when '6'
      bullet_points(1..11, 'd6_mid')
    else
      text 'OUT OF RANGE'
    end
  end

  def inferior_quality(title)
    case title
    when '1'
      bullet_points(1..7, 'd1_low')
    when '2'
      if is_cda?
        bullet_points(1..10, 'd2_low_res')
      else
        bullet_points(1..9, 'd2_low_non')
      end
    when '3'
      if is_cda?
        bullet_points(1..7, 'd3_low_res')
      else
        bullet_points(1..6, 'd3_low_non')
      end
    when '4'
      bullet_points(1..11, 'd4_low')
    when '5'
      if is_cda?
        bullet_points(1..12, 'd5_low_res')
      else
        bullet_points(1..6, 'd5_low_non')
      end
    when '6'
      bullet_points(1..11, 'd6_low')
    else
      text 'OUT OF RANGE'
    end
  end

  def additional_feedback
    domain_title(localize_text('additional_feedback'))
    text localize_text('additional_comments')
  end

  def comparison_chart
    domain_title(localize_text('comparison_chart'))
    text localize_text("#{@center.center_type}_comparison")
    move_down 10
    data = if is_cda?
             [
               ['', @center.name, I18n.t('report.public', type: @center.center_type, locale: @language),
                I18n.t('report.private', type: @center.center_type, locale: @language),
                I18n.t('report.both', type: @center.center_type, locale: @language)],
               [localize_text('center_score'), @scores[@center.identifier]['Score'], @public_scores['Score'], @private_scores['Score'], @nat_avg_scores['Score']]
             ]
           else
             [
               ['', @center.name, I18n.t('report.national', type: @center.center_type, locale: @language)],
               [localize_text('center_score'), @scores[@center.identifier]['Score'], @nat_avg_scores['Score']]
             ]
           end
    @score_scheme.domains.sort_by { |domain| domain.title.to_i }.each do |domain|
      ds = @scores[@center.identifier][domain.title]
      ds = ds.round(2) if ds != ''
      if is_cda?
        data << [localize_text("d#{domain.title}_title"), '', '', '', '']
        data << [localize_text('domain_score'), ds, @public_scores[domain.title], @private_scores[domain.title], @nat_avg_scores[domain.title]]
      else
        data << [localize_text("d#{domain.title}_title"), '', '']
        data << [localize_text('domain_score'), ds, @nat_avg_scores[domain.title]]
      end
      domain.subdomains.sort_by { |subdomain| subdomain.title.to_f }.each do |subdomain|
        next if subdomain.title == '1.5' || subdomain.title == '5.9'

        sds = @scores[@center.identifier][subdomain.title]
        sds = sds.round(2) if sds != ''
        name = @score_scheme.instrument.language == @language ? subdomain.title_name : full_sanitizer.sanitize(subdomain.translated_title_name(@language))
        data << if is_cda?
                  [name, sds, @public_scores[subdomain.title], @private_scores[subdomain.title], @nat_avg_scores[subdomain.title]]
                else
                  [name, sds, @nat_avg_scores[subdomain.title]]
                end
      end
    end

    table(data) do
      cells.borders = []
      cells.align = :center
      columns(0..4).borders = %i[left right]

      row(0..1).borders = %i[left top right bottom]
      row(3).borders = %i[left right bottom]
      row(0..3).font_style = :bold
      row(2).background_color = '808080'
      row(3).columns(0).font_style = :bold_italic

      row(8).borders = %i[left top right]
      row(8).font_style = :bold
      row(8).background_color = '808080'
      row(9).borders = %i[left right bottom]
      row(9).columns(0).font_style = :bold_italic

      row(19).borders = %i[left top right]
      row(19).font_style = :bold
      row(19).background_color = '808080'
      row(20).borders = %i[left right bottom]
      row(20).columns(0).font_style = :bold_italic

      row(27).borders = %i[left top right]
      row(27).font_style = :bold
      row(27).background_color = '808080'
      row(28).borders = %i[left right bottom]
      row(28).columns(0).font_style = :bold_italic

      row(35).borders = %i[left top right]
      row(35).font_style = :bold
      row(35).background_color = '808080'
      row(36).borders = %i[left right bottom]
      row(36).columns(0).font_style = :bold_italic

      row(45).borders = %i[left top right]
      row(45).font_style = :bold
      row(45).background_color = '808080'
      row(46).borders = %i[left right bottom]
      row(46).columns(0).font_style = :bold_italic

      row(49).borders = %i[left right bottom]

      data.each_with_index do |datum, index|
        next if index == 0

        datum.each_with_index do |score, ind|
          next if ind == 0

          row(index).columns(ind).background_color = 'DCDCDC' if score == '' && !datum[0].include?(':')
          row(index).columns(ind).background_color = 'FEC15D' if score != '' && score > 3.0 && score < 5.01
          row(index).columns(ind).background_color = 'F06A78' if score != '' && score < 3.01
        end
      end
    end

    move_down 5
    text localize_text('no_color')
    text localize_text('orange_color'), inline_format: true
    text localize_text('red_color'), inline_format: true
    text localize_text('gray_color'), inline_format: true
  end
end
