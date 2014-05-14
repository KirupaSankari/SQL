select sum(bytes)/1024/1024/1024 data_size_Gb from dba_segments;

select sum(bytes)/1024/1024/1024 free_space_Gb from dba_free_space;
