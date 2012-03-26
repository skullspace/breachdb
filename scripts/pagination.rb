class Pagination
  attr_reader :url, :count, :max_page, :page, :sort, :sortdir

  DEFAULT_PAGE_SIZE = 100
  MAX_PAGE_SIZE = 10000

  def initialize(url, params, total_rows, default_sort, default_sortdir)
    @url = url

    @count = params['count'].to_i
    @count = DEFAULT_PAGE_SIZE if(@count < 1)
    @count = DEFAULT_PAGE_SIZE if(@count > MAX_PAGE_SIZE)
  
    @max_page = ((total_rows - 1) / @count) + 1
  
    @page = params['page'].to_i
    @page = 1        if(@page < 1)
    @page = max_page if(@page > @max_page)
  
    @sort = params['sort']
    if(@sort.nil? || @sort !~ /^[a-z_]+$/)
      @sort = default_sort
    end
  
    @sortdir = params['sortdir']
    if(@sortdir.nil?)
      @sortdir = default_sortdir
    end
  
    @sortdir.upcase!
    if(@sortdir != 'ASC' && @sortdir != 'DESC')
      @sortdir = default_sortdir
    end
  end

  def opposite_sortdir
    return @sortdir == 'ASC' ? 'DESC' : 'ASC'
  end

  def get_html()
    return (@page ==         1 ? 'First': "<a href='#{get_url(nil, 1, nil, nil)}'>First</a>")        + ' | ' +
           (@page ==         1 ? 'Prev' : "<a href='#{get_url(nil, @page - 1, nil, nil)}'>Prev</a>") + ' | ' +
           (@page == @max_page ? 'Next' : "<a href='#{get_url(nil, @page + 1, nil, nil)}'>Next</a>") + ' | ' +
           (@page == @max_page ? 'Last' : "<a href='#{get_url(nil, @max_page, nil, nil)}'>Last</a>") +
           " (page #{@page} / #{@max_page})"
  end

  def get_url(count = nil, page = nil, sort = nil, sortdir = nil)
    return "#{url}?" + 
            "count=#{count.nil?     ? @count   : count}&" +
            "page=#{page.nil?       ? @page    : page}&" +
            "sort=#{sort.nil?       ? @sort    : sort}&" +
            "sortdir=#{sortdir.nil? ? @sortdir : sortdir}&"
  end
end
