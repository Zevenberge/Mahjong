module mahjong.share.numbers;

bool isOdd(const int i) pure
in
{ 
	assert(i >= 0); 
}
body
{ 
	return i % 2 == 1;
}
unittest{
	assert(isOdd(9));
	assert(!isOdd(8));
}
