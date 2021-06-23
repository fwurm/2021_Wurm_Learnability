function parsave(fn,data)
%saving data to location fn (useful in parfor-loops)
fprintf('   saving filename: %s\n',fn)
save(fn,'data')
end