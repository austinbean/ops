#import urlparse

# this worked as of 10/16/2020

import urllib 
import urllib3 
from bs4 import BeautifulSoup 
import json
import csv 
import operator 
import time 

from selenium import webdriver 
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.select import Select
from selenium.webdriver import ActionChains
from selenium.webdriver.common.by import By


ndcs = []
with open('/Users/austinbean/Desktop/programs/opioids/all_ndcs.csv', newline='') as csvf:
    rdr = csv.reader(csvf, delimiter=',')
    for row in rdr:
        ndcs.append(row[0])


driver = webdriver.Chrome()
alljs = []  # empty list to hold all json objects.
notfound = []




for ndc in ndcs:
    print(ndc)
    driver.get("http://www.hipaaspace.com/medical_billing/coding/national_drug_code/ndc_number_lookup.aspx")
    driver.find_element(By.ID, "tbxSearchRequest").send_keys(ndc)
    time.sleep(2)
    try: 
        driver.find_elements(By.ID, "Healthcare_Codes_Search_Results")
        print(len(driver.find_elements(By.ID, "Healthcare_Codes_Search_Results")))
        wait = WebDriverWait(driver, 5) 
        element = wait.until(EC.element_to_be_clickable((By.PARTIAL_LINK_TEXT, "JSON"))) 
        element.click() 
        # TODO: here iterate over items if more than one exist
        list1 = driver.find_elements_by_xpath("//*[contains(text(), 'NDC')]")
        list1_length = [len(x.text) for x in driver.find_elements_by_xpath("//*[contains(text(), 'NDC')]")]
        if len(list1) > 1:
            print("BIG NDC:", ndc)
        if len(list1) > 0:
            index, value = max(enumerate(list1_length), key=operator.itemgetter(1))
            j1 = json.loads(list1[index].text) # this grabs the whole json object
            j1["NDC"]["QueryCode"] = "~"+ndc 
            alljs.append(j1) 
        else:
            notfound.append(ndc)
    except :
        print("didn't find any for ", ndc)
        notfound.append(ndc)


# save the unfound items 
with open("/Users/austinbean/Desktop/programs/opioids/ndc_unfound_2.csv", 'w') as csv1:
    csw1 = csv.writer(csv1, delimiter = ',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
    for r in notfound:
        csw1.writerow(r)


empty = []
tm1 = []
for k in alljs[1]["NDC"].keys():
    tm1.append(k)

empty.append(tm1)   

for row in alljs:
    tmp = []
    for k1 in row["NDC"].keys():
        tmp.append(row["NDC"][k1])
    empty.append(tmp)



# save the JSON items 
    # NB: don't open w/ excel or the leading zeros from the querycode will be stripped.  
with open("/Users/austinbean/Desktop/programs/opioids/ndc_scraped.csv", 'w') as csv2:
    csw = csv.writer(csv2)
    csw.writerows(empty)




### This is going to do the unfound NDCs which I matched by hand:

nndcs = []
with open("/Users/austinbean/Desktop/programs/opioids/ndc_unfound.csv", 'r',  encoding='ISO 8859-1') as csv1:
    rdr = csv.reader(csv1, delimiter=',')
    for row in rdr:
        if row[4]=='YES' and row[1]!='':
            nndcs.append(row[1].rstrip())

nndcs[9] = '0378-9124-16'

driver = webdriver.Chrome()
nalljs = []  # empty list to hold all json objects.
nnotfound = []


for ndc in nndcs:
    print(ndc)
    driver.get(
        "http://www.hipaaspace.com/medical_billing/coding/national_drug_code/ndc_number_lookup.aspx")
    driver.find_element(By.ID, "tbxSearchRequest").send_keys(ndc)
    time.sleep(2)
    try:
        driver.find_elements(By.ID, "Healthcare_Codes_Search_Results")
        print(len(driver.find_elements(By.ID, "Healthcare_Codes_Search_Results")))
        wait = WebDriverWait(driver, 5)
        element = wait.until(EC.element_to_be_clickable((By.PARTIAL_LINK_TEXT, "JSON")))
        element.click()
        # TODO: here iterate over items if more than one exist
        list1 = driver.find_elements_by_xpath("//*[contains(text(), 'NDC')]")
        list1_length = [len(x.text) for x in driver.find_elements_by_xpath(
            "//*[contains(text(), 'NDC')]")]
        if len(list1) > 1:
            print("BIG NDC:", ndc)
        if len(list1) > 0:
            index, value = max(enumerate(list1_length),key=operator.itemgetter(1))
            # this grabs the whole json object
            j1 = json.loads(list1[index].text)
            j1["NDC"]["QueryCode"] = "~"+ndc
            nalljs.append(j1)
        else:
            nnotfound.append(ndc)
    except:
        print("didn't find any for ", ndc)
        nnotfound.append(ndc)


nempty = []
ntm1 = []
for k in nalljs[1]["NDC"].keys():
    ntm1.append(k)

nempty.append(ntm1)

for row in nalljs:
    tmp = []
    for k1 in row["NDC"].keys():
        tmp.append(row["NDC"][k1])
    nempty.append(tmp)


with open("/Users/austinbean/Desktop/programs/opioids/ndc_hand_found.csv", 'w') as csv2:
    csw = csv.writer(csv2)
    csw.writerows(nempty)
