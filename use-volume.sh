#!/bin/bash
 
case $1 in
 
  backup)
    docker run --rm -v $2:/volume -v $(pwd):/backup ubuntu tar cvf /backup/$2.tar /volume
    ;;
 
  restore)
    docker run --rm -v $(pwd):/backup -v $2:/volume ubuntu bash -c "cd /volume && tar xvf /backup/$2.tar --strip 1"
    ;;
 
esac
