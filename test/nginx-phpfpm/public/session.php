<?php
session_start();
$_SESSION['test'] = "hello";
if (! isset($_SESSION['count'])) {
  echo "init session count";
  $_SESSION['count'] = 0;
} else {
  $_SESSION['count'] += 1;
}

echo "Session content:";
print_r($_SESSION);
