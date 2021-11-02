function starbright, map1, sflux

  sz = size(map1)

  ;;Add brightness to image
  num = sz[2]/ 2

  map1(num-1,num-1) = map1(num-1,num-1) + sflux/4.0
  map1(num,num-1) = map1(num,num-1) + sflux/4.0
  map1(num-1,num) = map1(num-1,num) + sflux/4.0
  map1(num,num) = map1(num,num) + sflux/4.0

  return, map1
end