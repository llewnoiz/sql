ALTER TRIGGER [dbo].[trigger_test_history]
   ON  [dbo].[test]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	declare @TableName nvarchar(500)	
	declare @sql nvarchar(MAX)
	declare @columns NVARCHAR(MAX)
	declare @values NVARCHAR(MAX);
	declare @ColumCount int
	declare @ColumCountMax int
	declare @RowCount int
	declare @RowCountMax int
	

	declare @result nvarchar(max)
	declare @tmpName nvarchar(max) 
	declare @tmpType nvarchar(max) 							
	declare @tmpQuery nvarchar(max) 
	declare @param nvarchar(max) 
	declare @tmpVal nvarchar(max)	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.	
	--SET NOCOUNT ON;

	SET @TableName = 'test';
	SET @columns = '';
	SET @values = '';
	SET @ColumCount = 1;
	SET @ColumCountMax = 0;
	SET @RowCount = 1;
	SET @RowCountMax = 0;
	 -- INSERT 작업인 경우
    IF EXISTS (SELECT * FROM INSERTED) AND NOT EXISTS (SELECT * FROM DELETED)
    BEGIN

		-- current table colums information 
		select *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn into #rp_inserted from inserted;
		select @RowCountMax = count(*) from #rp_inserted;

		SELECT @columns = @columns + column_name + ','
		FROM information_schema.columns
		WHERE table_name = @TableName;
		SET @columns = LEFT(@columns, LEN(@columns) - 1);
		
		SELECT ORDINAL_POSITION as id , column_name as name, DATA_TYPE as type  into #tempColumnTables
		FROM information_schema.columns
		WHERE table_name = @TableName;

		select @ColumCountMax = count(*) from #tempColumnTables;
		SET @sql = 'insert into ' +@TableName+' ('+@columns + ') '
		SET @sql = @sql + ' values';

	
		while @RowCount <= @RowCountMax
		begin 
			SET @ColumCount = 1;
			
			while @ColumCount <= @ColumCountMax
			begin
							
				set @tmpName = ( select name from #tempColumnTables where id = @ColumCount );		
				set @tmpType = (select type from #tempColumnTables where id = @ColumCount);
				set @tmpQuery = N'select @result = '+@tmpName+' from #rp_inserted where rn =' + CAST(@RowCount AS nvarchar);
				set @param = N'@result nvarchar(max) OUTPUT';						
				set @tmpVal = '';
				EXEC sp_executesql @tmpQuery, @param, @result=@tmpVal OUTPUT;

				if @tmpType in ('char','varchar','nvarchar','text') 
				begin
					set @values = @values + '''' +@tmpVal + '''' + ','
				end
				else					
				begin
					set @values = @values + @tmpVal + ','
				end

				set @ColumCount = @ColumCount + 1;
				
			end;
			SET @values = LEFT(@values, LEN(@values) - 1);
			
			-- make dynamic sql
			SET @sql = @sql + ' ('+@values+'),';
			SET @values = ''
			SET @RowCount = @RowCount + 1;
			
		end

		SET @sql = LEFT(@sql, LEN(@sql) - 1) + ';';
		-- insert history db query		
		insert into history values(1,@sql,1);
    END;

	-- DELETE 작업인 경우
    IF EXISTS (SELECT * FROM DELETED) AND NOT EXISTS (SELECT * FROM INSERTED)
    BEGIN
		
		-- current table colums information 
		select distinct *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn into #rp_deleted from deleted;
		select @RowCountMax = count(*) from #rp_deleted;

		SELECT ORDINAL_POSITION as id , column_name as name, DATA_TYPE as type  into #tempDelColumnTables
		FROM information_schema.columns
		WHERE table_name = @TableName;

		select @ColumCountMax = count(*) from #tempDelColumnTables;
		
		while @RowCount <= @RowCountMax
		begin 
			SET @ColumCount = 1;
			SET @sql = 'delete ' +@TableName
			SET @sql = @sql + ' where';

			while @ColumCount <= @ColumCountMax
			begin
							
				set @tmpName = ( select name from #tempDelColumnTables where id = @ColumCount );		
				set @tmpType = (select type from #tempDelColumnTables where id = @ColumCount);
				set @tmpQuery = N'select @result = ' +@tmpName+ ' from #rp_deleted where rn =' + CAST(@RowCount AS nvarchar);
				set @param = N'@result nvarchar(max) OUTPUT';						
				set @tmpVal = '';
				EXEC sp_executesql @tmpQuery, @param, @result=@tmpVal OUTPUT;


				if @tmpType in ('char','varchar','nvarchar','text') 
				begin
					set @values = @values +' '+ @tmpName + '=' +'''' +@tmpVal +'''' +' and'
				end
				else					
				begin
					set @values = @values +' '+ @tmpName + '=' + @tmpVal + ' and'
				end
				
				set @ColumCount = @ColumCount + 1;
				
			end;

			-- make dynamic sql		
			SET @sql = @sql +@values;
			SET @values = ''
			SET @sql = LEFT(@sql, LEN(@sql) - 3);
			SET @sql =@sql + ';';
			-- insert history db query		
			insert into history values(1,@sql,2);
			SET @RowCount = @RowCount + 1;
			
		end

    END;


    -- UPDATE 작업인 경우
    IF EXISTS (SELECT * FROM INSERTED) AND EXISTS (SELECT * FROM DELETED)
    BEGIN

		select distinct *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn into #up_deleted from deleted;
		select distinct *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn into #up_inserted from inserted;
		
		select @RowCountMax = count(*) from #up_deleted;

		SELECT ORDINAL_POSITION as id , column_name as name, DATA_TYPE as type  into #tempUpColumnTables
		FROM information_schema.columns
		WHERE table_name = @TableName;


		select @ColumCountMax = count(*) from #tempUpColumnTables;


		while @RowCount <= @RowCountMax
		begin 
			SET @ColumCount = 1;
			SET @sql = 'update ' +@TableName			
			declare @setString nvarchar(max) = ' set'
			declare @whereString nvarchar(max) = ' where'
			declare @tmpOldVal nvarchar(max) ='';
			declare @tmpNewVal nvarchar(max) ='';

			while @ColumCount <= @ColumCountMax
			begin
							
				set @tmpName = ( select name from #tempUpColumnTables where id = @ColumCount );		
				set @tmpType = (select type from #tempUpColumnTables where id = @ColumCount);
				
				set @tmpQuery = N'select @result = ' +@tmpName+ ' from #up_deleted where rn =' + CAST(@RowCount AS nvarchar);
				set @param = N'@result nvarchar(max) OUTPUT';						
				set @tmpOldVal = '';
				EXEC sp_executesql @tmpQuery, @param, @result=@tmpOldVal OUTPUT;


				set @tmpQuery = N'select @result = ' +@tmpName+ ' from #up_inserted where rn =' + CAST(@RowCount AS nvarchar);
				set @param = N'@result nvarchar(max) OUTPUT';						
				set @tmpNewVal = '';
				EXEC sp_executesql @tmpQuery, @param, @result=@tmpNewVal OUTPUT;


				if @tmpType in ('char','varchar','nvarchar','text') 
				begin
					set @setString = @setString +' '+ @tmpName + '=' +'''' +@tmpNewVal +'''' +',' 
					set @whereString = @whereString +' '+ @tmpName + '=' +'''' +@tmpOldVal +'''' +' and'
				end
				else					
				begin
					set @setString = @setString +' '+ @tmpName + '=' +@tmpNewVal  +',' 
					set @whereString = @whereString +' '+ @tmpName + '=' + @tmpOldVal + ' and'
				end
				
				set @ColumCount = @ColumCount + 1;
				
			end;

			-- make dynamic sql					
			SET @setString = LEFT(@setString, LEN(@setString) - 1);
			SET @whereString = LEFT(@whereString, LEN(@whereString) - 3);
			SET @sql = @sql + @setString + @whereString;			

			SET @sql =@sql + ';';
			-- insert history db query		
			insert into history values(1,@sql,3);
			SET @RowCount = @RowCount + 1;
			
		end

    END;
END