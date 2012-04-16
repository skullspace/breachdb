require 'rubygems'
require 'mysql'

require 'pagination'

require '/home/ron/auth.rb'

class Db
  @@my = nil
  CHUNK_SIZE = 10000
  DEBUG = true
  DEBUG_QUERY = false

  def self.debug(str)
    if(DEBUG)
      puts(">> #{str}")
    end
  end

  ##
  # This needs to be called at the start of the program to initiate the
  # database connection.
  ##
  def self.initialize()
    # Only initialize the database once (not really threadsafe, but not a big
    # deal)
    if(@@my.nil?)
      @@my = Mysql::new(DB_HOST, DB_USERNAME, DB_PASSWORD, DB_DB)
    end
  end

  ##
  # Perform a SQL query.
  ##
  def self.query(query)
    if(@@my.nil?)
      throw :DBNotInitialized
    end

    if(DEBUG_QUERY)
      puts(query)
      File.open("/tmp/query", "a") do |f|
        f.puts(query)
        f.puts()
      end
    end

    return @@my.query(query)
  end

  ##
  # Perform a query based on the given 'query_params' structure.
  #
  # The query_params structure is a table with the following elements (all elements 
  # are optional):
  # * :columns  : An Array of columns. Each column is either a String representing a single column name, or a Table containing :name, :as, and :aggregate (eg. 'SUM', 'COUNT', etc).
  # * :table    : A String represting the table we're selecting from. Defaults to the class's table_name.
  # * :join     : A single Hash (or Array of hashes) containing :type (eg, 'LEFT JOIN'), :table, :column1, and :column2. 
  # * :where    : The 'where' clause, as a String.
  # * :orderby  : A String, representing which column to order by; a Hash, containing :column and (optionally) :dir; or an Array of such hashes.
  # * :groupby  : A String or an Array of strings that list which columns to put in the GROUP BY clause.
  # * :limit    : A String, Fixnum, or Hash that contains :page and :pagesize
  # 
  # There are also special arguments that can override the others:
  # * :pagination : An instance of the Pagination class; overrides :orderby and :limit
  #
  ##
  def self.get_query(query_params)
    query_params = query_params.nil? ? {} : query_params.clone

    # If a 'pagination' was given, override :orderby and :limit
    if(!query_params[:pagination].nil?)
      pagination = query_params[:pagination]
      query_params[:limit]   = { :page => pagination.page, :pagesize => pagination.count }
      query_params[:orderby] = { :column => pagination.sort, :dir => pagination.sortdir}
    end

    # Default the column list to '*'
    columns = "SELECT *\n"

    # If a columns array was given, each element consists of an 'aggregate'
    # and a 'name'
    if(!query_params[:columns].nil?)
      # Make sure we have a String, a Hash, or an Array
      if(!query_params[:columns].is_a?(String) && !query_params[:columns].is_a?(Hash) && !query_params[:columns].is_a?(Array))
        throw :BadType
      end

      # If we have a String, convert it into a Hash
      if(query_params[:columns].is_a?(String))
        query_params[:columns] = { :name => query_params[:columns] }
      end

      # If we have a Hash, convert it into an Array
      if(query_params[:columns].is_a?(Hash))
        query_params[:columns] = [ query_params[:columns] ]
      end

      # Now we know we have an Array to work with
      columns = []
      query_params[:columns].each do |col|
        if(!col[:raw_name].nil?)
          columns << Mysql::quote(col[:raw_name])
        else
          aggregate = col[:aggregate].nil? ? nil : Mysql::quote(col[:aggregate])
          name      = col[:name] == '*'    ? '*' : "`#{Mysql::quote(col[:name])}`"
          as        = col[:as].nil?        ? nil : "`#{Mysql::quote(col[:as])}`"
          columns << (aggregate.nil? ? "#{name}" : "#{aggregate}(#{name})") + (as.nil? ? '' : " AS #{as}")
        end
      end
      columns = "SELECT #{columns.join(", ")}"
    end

    # Use the table directly
    if(query_params[:table].nil?)
      query_params[:table] = table_name
    end
    table = "FROM `#{Mysql::quote(query_params[:table])}`"

    # Default join to nothing
    join = ''

    # If a join array was given, it's a list of tables that contain type,
    # table, col1, and col2
    if(!query_params[:join].nil?)
      # Make sure it's either a Array or a Hash
      if(!query_params[:join].is_a?(Array) && !query_params[:join].is_a?(Hash))
        throw :BadType
      end

      # Handle a Hash properly (by converting it to an Array with a single
      # element)
      if(query_params[:join].is_a?(Hash))
        query_params[:join] = [ query_params[:join] ]
      end

      query_params[:join].each do |join|
        type  = join[:type].nil? ? join[:type] : 'JOIN'
        table = join[:table]
        col1  = join[:column1]
        col2  = join[:column2]

        join << "\t#{type} `#{table}` ON `#{col1}`=`#{col2}`"
      end
      join = join.join("\n")
    end

    # Default where to blank
    where = ''

    # Use the where clause as-is, if it's present
    if(!query_params[:where].nil?)
      where = "WHERE\n#{query_params[:where]}"
    end

    # Default orderby to blank
    orderby = ''

    # If the orderby array exists, it's an array of tables containing column
    # and dir
    if(!query_params[:orderby].nil?)
      # Make sure we have a String, a Hash, or a Array
      if(!query_params[:orderby].is_a?(String) && !query_params[:orderby].is_a?(Hash) && !query_params[:orderby].is_a?(Array))
        throw :BadType
      end

      # Handle String arguments (by converting it into a Hash)
      if(query_params[:orderby].is_a?(String))
        query_params[:orderby] = { :column => query_params[:orderby] }
      end

      # Handle Hash arguments (by converting them into an Array)
      if(query_params[:orderby].is_a?(Hash))
        query_params[:orderby] = [ query_params[:orderby] ]
      end

      # Finally, handle Array arguments
      orderby = []
      query_params[:orderby].each do |o|
        if(!o[:column].nil? && o[:column] != '')
          column = "`#{Mysql::quote(o[:column])}`"
          dir = 'ASC'
          if(!o[:dir].nil?)
            dir = o[:dir].upcase == 'DESC' ? 'DESC' : 'ASC' # Can only be 'ASC'/'DESC'
          end

          orderby << "\t#{column} #{dir}"
        end
      end

      # If we have a length of 0, we had no 'orderby' clause (this is for
      # reverse compatibility)
      if(orderby.length == 0)
        orderby = ''
      else
        orderby = "ORDER BY\n" + orderby.join("\n") + "\n"
      end
    end

    # Default groupby to blank
    groupby = ''

    # If groupby exists, it's simply an array of columns
    if(!query_params[:groupby].nil?)
      # Make sure we have either a string or an Array
      if(!query_params[:groupby].is_a?(String) && !query_params[:groupby].is_a?(Array))
        throw :BadType
      end

      # Handle a String by converting it to an Array
      if(query_params[:groupby].is_a?(String))
        query_params[:groupby] = [ query_params[:groupby] ]
      end

      # Handle an Array
      groupby = []
      query_params[:groupby].each do |g|
        groupby << "\t`#{Mysql::quote(g)}`"
      end
      groupby = "GROUP BY #{groupby.join("\n")}"
    end

    # Default limit to blank
    limit = ''

    # If limit exists, it's a table containing :pagesize and :page
    if(!query_params[:limit].nil?)
      # Make sure we have either a Hash, a String, or a Fixnum for limit
      if(!query_params[:limit].is_a?(Hash) && !query_params[:limit].is_a?(String) && !query_params[:limit].is_a?(Fixnum))
        throw :BadType
      end

      # Convert a String or Fixnum size to a Hash
      if(query_params[:limit].is_a?(String) || query_params[:limit].is_a?(Fixnum))
        query_params[:limit] = { :pagesize => query_params[:limit] }
      end

      # Handle the Hash
      page      = query_params[:limit][:page].to_i || 1
      page_size = query_params[:limit][:pagesize].to_i || 10

      # Make sure we don't try to get a negative page
      if(page < 1)
        page = 1
      end

      limit = "LIMIT #{(page-1) * page_size}, #{page_size}"
    end

    return "
#{columns}
#{table}
#{join}
#{where}
#{groupby}
#{orderby}
#{limit}
"
  end

  ##
  # Perform a query. See the documentation for get_query() for information on
  # how the query_params argument works. 
  ##
  def self.query_ex(query_params)
    return result_to_list(query(get_query(query_params)))
  end

  # A handy little wrapper around query_ex to get the top rows from a table
  def self.get_top(column, count, query_params = nil)
    query_params = query_params.nil? ? {} : query_params.clone

    query_params[:orderby] = {:column=>column, :dir=>'DESC'}
    query_params[:limit]  = count

    return query_ex(query_params)
  end

  # A handy wrapper aorund query_ex that performs a GROUP BY/SUM() on a column
  # and takes the top-x from that column on the result
  def self.get_top_sum(sum_column, groupby_column, count, query_params = nil)
    query_params = query_params.nil? ? {} : query_params.clone

    query_params[:columns] = [
        { :name => '*' },
        { :name => sum_column, :aggregate => 'SUM', :as => sum_column }
    ]
    query_params[:groupby] = groupby_column;

    return get_top(sum_column, count, query_params)
  end

  def self.get_count_ex(query_params = nil)
    query_params = query_params.nil? ? {} : query_params.clone

    query_params[:columns] = { :raw_name => '1' }
    query = get_query(query_params)

    result = result_to_list(query("
                    SELECT COUNT(*) AS `RESULT`
                    FROM
                    (
                      #{query}
                    ) AS `a`"))

    return result.pop['RESULT'].to_i
  end

  ##
  # Convert the result from a MySQL call into an array. This is either an
  # associative array (if column is nil) or an array representing a single
  # column (if column is set). 
  #
  # @param result The result of a mysql query
  # @param column [optional] If set, only return a specific column
  #
  # @return Either an associative array of the rows, or an array representing
  #  the single given column
  def self.result_to_list(result, column = nil)
    list = []
    result.each_hash() do |r|
      if(column.nil?)
        list << r
      else
        list << r[column]
      end
    end
    return list
  end

  ## 
  # Read a table in chunks. This can work in two ways:
  #
  # 1) read-only mode - This reads the table a little at a time using LIMIT BY
  #    to get only what we need.
  # 2) read/write mode - This reads the entire table, and passes it to the
  #    function a little at a time. This obviously takes a lot more memory,
  #    but will work if the function changes within the callback.
  #
  # @param column If set, only return a single column
  # @param size   The size of the chunks - the default CHUNK_SIZE is probably best
  # @param where  Add a WHERE clause to the query
  # @param is_read_only Enable/disable read-only mode
  def self.each_chunk(column = nil, size = CHUNK_SIZE, where = nil, is_read_only = true)
    debug("Reading table `#{table_name}` in chunks of #{size} rows #{column.nil? ? '' : "(column: #{column})"}")
    if(is_read_only)
      i = 0
      loop do
        result = result_to_list(query("
          SELECT #{column.nil? ? '*' : "`#{Mysql::quote(column)}`"}
          FROM `#{Mysql::quote(table_name)}`
          #{ where.nil? ? "" : "WHERE #{where}"}
          ORDER BY `#{id_column}`
          LIMIT #{i}, #{size}
        "), column)

        if(result.size == 0)
          break
        end
        yield result
        i = i + size
      end
    else
      # Get the results
      # TODO: Can we just get the id column?
      r = result_to_list(query("
        SELECT #{column.nil? ? '*' : "`#{Mysql::quote(column)}`"}
        FROM `#{Mysql::quote(table_name)}`
        #{ where.nil? ? "" : "WHERE #{where}"}
      "), column)

      i = 0
      r.each_slice(size) do |slice|
        i += size
        yield slice
      end
    end
  end

  ##
  # Look up the values for a specific column in the table and return the
  # corresponding ID fields. Optionally verify that all requested values
  # were found and error out if they aren't.
  #
  # @param field_name The name of the field we're looking up.
  # @param values An array of values to look up.
  # @param verify_all If set to true, validate that every value passed in
  #        returns at least one result.
  #
  # @return A table where the key is the value and the value is an array of one
  #         or more ids
  ##
  def self.get_ids(field_name, values, verify_all)
#    debug("Looking up #{values.size} id values in #{table_name}.#{field_name}...")
    # Uniq-ify the values (otherwise, it messes up our count)
    values = values.uniq

    # Make the values sql safe
    where_list = values.collect() do |v| "'#{Mysql::quote(v)}'" end

    query = " SELECT `#{Mysql::quote(id_column)}` AS `id`, `#{Mysql::quote(field_name)}` AS `field`
              FROM `#{Mysql::quote(table_name)}`
              WHERE `#{Mysql::quote(field_name)}` IN (#{where_list.join(",")})"
    result = query(query)

    ids = {}
    result.each_hash() do |i|
      if(ids[i['field']].nil?)
        ids[i['field']] = [i['id']]
      else
        ids[i['field']] << i['id']
      end
    end

    # This is a very important sanity check that ensures we get exactly one row
    # back per hash
    if(verify_all)
      if(ids.keys.size() != values.size())
        puts("ERROR! Expected #{values.size()} values, got #{ids.keys.size} from table #{table_name}! (Error written to file)")
        File.open("/tmp/db.expected", "w").puts(values)
        File.open("/tmp/db.got", "w").puts(ids.keys)
        File.open("/tmp/db.err", "w").puts(query)
        exit()
      end
    end

    return ids
  end

  ##
  # Get the row with the given id.
  ##
  def self.get(id)
    return self.list("`#{id_column}`='#{Mysql::quote(id)}'").pop
  end

  ##
  # Get a list of all rows that match the given id or just all rows.
  #
  # This is designed for subclasses, it won't work directly.
  #
  # @param id An ID to look up.
  # @param where A where clause.
  # @param orderby The field to order the results by. Can be an array for
  #  multiple fields.
  # @param orderby_dir The orderby direction (ASC/DESC). Must be an array if
  #  orderby is an array.
  # @param page_size The number of results to display on each page.
  # @param page The number of the page to display
  #
  # @return The results as a list of associative arrays
  ##
  def self.list(where = nil, orderby = nil, orderby_dir = nil, page_size = nil, page = nil)
    page = 1 if(page.nil? || page < 1)
    page_size = 10 if(page_size.nil? || page_size == 0)

    return query_ex({
      :columns => "*",
      :table => table_name,
      :where => where,
      :orderby => [ {
          :column => orderby,
          :dir    => orderby_dir
        }
      ],
      :limit => {
        :pagesize => page_size,
        :page => page
      }
    })

    # Get the results
    return result_to_list(query("
      SELECT *
      FROM `#{Mysql::quote(table_name)}`
      #{where.nil? ? "" : "WHERE #{where}"}
      #{orderby}
      #{limit}
    "))
  end

  ##
  # Get the number of rows that are returned by the query with the given
  # 'where' clause.
  ##
  def self.get_count(where = nil)
    result = result_to_list(query("
      SELECT COUNT(*) AS `count`
      FROM `#{table_name}`
      #{where.nil? ? '' : "WHERE #{where}"}
    "))
    return result.pop['count'].to_i
  end

  ##
  # Insert one or more rows into the table. The to_import argument is an 
  # associative array with the key being a column and the value being the
  # data to insert into the database. The value can optionally be an array,
  # in which case it inserts multiple rows with the same static values, and 
  # different array values. If multiple columns have array values, the arrays
  # have to be the same length (or an error is thrown). 
  #
  # This is designed for subclasses, it won't work directly.
  #
  # @param to_import An associative array where the key is the column name, and
  #  the value is either a string or an array. If more than one of the values
  #  are arrays, they have to be the same length.
  # @param id Set to the id of the row to edit, if we're editing a value.
  #
  # @return The ID of the last row added, or the id of the row that was edited.
  ##
  def self.insert_rows(to_import, id = nil)
    if(id.nil?)
      keys = to_import.keys
      columns = keys.collect() do |column| "`#{Mysql::quote(column)}`" end
      multi = []
      count = 0
      keys.each do |key|
        if(to_import[key].is_a?(Array))
          multi << key
          if(count == 0)
            count = to_import[key].size
          else
            if(count != to_import[key].size)
              throw :MultipleSizesError
            end
          end
        end
      end

      debug("Inserting #{count <= 1 ? '1 row' : "#{count} rows"} into the database...")

      rows = []
      if(count == 0)
        values  = "(" + (keys.collect() do |column| "'#{Mysql::quote(to_import[column])}'" end).join(",") + ")"
        rows << values
      else
        0.upto(count-1) do |i|
          this_row = to_import.clone

          multi.each do |m|
            this_row[m] = this_row[m][i]
          end

          rows << "(" + (keys.collect() do |column| "'#{Mysql::quote(this_row[column])}'" end).join(",") + ")"
        end
      end

      rows.each_slice(CHUNK_SIZE) do |slice|
        query("INSERT INTO `#{table_name()}` (#{columns.join(',')}) VALUES #{slice.join(',')}")
      end

      return @@my.insert_id.to_s
    else
      rows = []

      to_import.each_pair do |column, value|
        rows << "`#{Mysql::quote(column)}`='#{Mysql::quote(value)}'"
      end

      query("UPDATE `#{table_name()}` SET #{rows.join(', ')} WHERE `#{id_column()}`='#{Mysql::quote(id.to_s)}'")
      return id
    end
  end

  ##
  # Take the result of a query and generate a HTML table.
  #
  # @param table A table of values in the table. This is simply an associative
  #  array, so it can use the result of result_to_list().
  # @param columns An array of columns to display. Each column is represented
  #  by a table containing:
  #  * :heading - the heading name
  #  * :field - the name of the field (within the table argument)
  #  * :sortby - the database column to sort by when the heading is clicked
  #  * :class - [optional] the css class for the column (default is :field)
  #  * :link - [optional] a url to link to in the field
  # @param css_class [optional] The table's class (default is the table name)
  # TODO
  #
  # @return An HTML table.
  ##
  def self.html_table(table, columns, css_class = nil, pagination = nil)
    str = ""

    css_class = css_class || table_name()

    str += "<table class='#{css_class}'>\n"
    str += "\t<tr>\n"
    columns.each do |c|
      str += "\t\t<th class='#{c[:class].nil? ? c[:field] : c[:class]}'>"
      if(pagination.nil? || c[:sortby].nil?)
        str += "#{c[:heading]}"
      else
        if(c[:sortby] == pagination.sort)
          str += "<a href='#{pagination.get_url(nil, nil, nil, pagination.opposite_sortdir)}'>#{c[:heading]}</a>"
        else
          str += "<a href='#{pagination.get_url(nil, nil, c[:sortby], 'ASC')}'>#{c[:heading]}</a>"
        end
      end
      str += "</th>\n"
    end

    table.each do |r|
      str += "\t<tr>\n"
      columns.each do |c|
        str += "\t\t<td class='#{c[:class].nil? ? c[:field] : c[:class]}'>"
        str += r[c[:field]]
        str += "</td>\n"
      end
      str += "\t</tr>\n"
    end

    str += "\t</tr>"
    str += "</table>\n"

    return str
  end

  ##
  # Get a HTML link to a page with the given id.
  #
  # @param id The ID to link to.
  # @param text The text for the link.
  # @param css_class [optional] The CSS class of the link
  #
  # @return HTML code for the link.
  ##
  def self.html_get_link(id, text, css_class = nil)
    return "<a href='/#{table_name}/#{id}' #{css_class.nil? ? '' : "class='#{css_class}'"}>#{text}</a>"
  end

  ##
  # Get a HTML link to search for a field with the given value
  #
  # @param search_string The search string to use.
  # @param text The text for the link.
  # @param css_class [optional] The CSS class of the link
  #
  # @return HTML code for the link.
  ##
  def self.html_get_search(search_string, text, css_class = nil)
    search_string = search_string.gsub("'", '&apos;').gsub('"', '&quot;').gsub('<', '&lt;').gsub('>', '&gt;')
    return "<a href='/search/#{table_name}/?#{table_name}=#{search_string}' #{css_class.nil? ? '' : "class='#{css_class}'"}>#{text}</a>"
  end

  ##
  # A method for subclasses to implement.
  ##
  def self.table_name()
    throw :NotImplementedError
  end

  ##
  # A method for subclasses to implement.
  ##
  def self.id_column()
    throw :NotImplementedError
  end

  ##
  # A method for subclasses to implement.
  ##
  def self.cache_update()
    throw :NotImplementedError
  end
end

