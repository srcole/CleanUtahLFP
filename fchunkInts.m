function chunkse = fchunkInts(ints,minchunk)
% take an array of integers and separate it into continuous chunks

B = length(ints); % Number of bins to chunk
cur_chunk_len = 1;
cur_int = ints(1);
chunk_num = 1;

chunksePRE = [];
chunklens = [];

for b=2:B
    if ints(b) == cur_int + 1
        cur_chunk_len = cur_chunk_len + 1;
    else
        chunksePRE(chunk_num,1:2) = [ints(b-1)-cur_chunk_len+1, ints(b-1)];
        
        chunklens(chunk_num) = cur_chunk_len;
        cur_chunk_len = 1;
        chunk_num = chunk_num + 1;
    end
    cur_int = ints(b);
end

% Classify the last chunk
chunksePRE(chunk_num,1:2) = [ints(B)-cur_chunk_len+1, ints(B)];
chunklens(chunk_num) = cur_chunk_len;

% Filter out the chunks less than the min chunk length
chunkse = chunksePRE(chunklens>=minchunk,:);