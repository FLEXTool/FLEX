#!/usr/bin/python

import os
import sys
import getopt

headerTemplate = """/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * This file was built by running
 *
 *   ./image_to_code.py %(args)s
 *
 * Thanks to the Facebook SDK for providing the base for this script
 */
"""

def bytes_from_file(filename, chunksize=8192):
  with open(filename, "rb") as f:
    while True:
      chunk = f.read(chunksize)
      if chunk:
        for b in chunk:
          yield b
      else:
        break

def write_header_file(header, className, outputFile):
  with open(outputFile, "w") as f:
    f.write(header)
    f.write("""
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

""")
    f.write("@interface " + className + " : NSObject\n\n")
    f.write("+ (UIImage *)image;\n\n")
    f.write("@end")

def write_implementation_file(inputFile, header, className, outputFile):
  formattedBytes = ["0x{0:02x}".format(ord(x)) for x in bytes_from_file(inputFile)]
  with open(outputFile, "w") as f:
    f.write(header)
    f.write("\n")
    f.write("#import \"" + className + ".h\"\n")
    f.write("#import \"FLEXImageLoader.h\"\n\n")

    # Write standard bytes out
    f.write("const Byte " + className + "_standard[] = {\n")
    f.write(", ".join(formattedBytes))
    f.write("\n")
    f.write("};\n")

    
    # Write retina if present
    useRetina = True
    try:
      (name, ext) = inputFile.rsplit(".", 1)
      name = name + "@2x"
      formattedBytes = ["0x{0:02x}".format(ord(x)) for x in bytes_from_file(name + "." + ext)]
      f.write("const Byte " + className + "_retina[] = {\n")
      f.write(", ".join(formattedBytes))
      f.write("\n")
      f.write("};\n")
    except IOError:
      useRetina = False

    # Enter the bundle path override
    # strip of the PNG that was added for our class name for the resource name
    bundlepath = "@\"" + "FacebookSDKImages/" + className[0:-3] + ".png\""

    f.write("\n")
    f.write("@implementation " + className + "\n\n")
    f.write("+ (UIImage *)image {\n")
    f.write("    return [FLEXImageLoader imageFromBytes:" + className + "_standard ")
    f.write("length:sizeof(" + className + "_standard)/sizeof(" + className + "_standard[0]) ")
    if useRetina:
      f.write("fromRetinaBytes:" + className + "_retina ")
      f.write("retinaLength:sizeof(" + className + "_retina)/sizeof(" + className + "_retina[0])];\n")
    else:
      f.write("fromRetinaBytes:NULL ")
      f.write("retinaLength:0];\n")
    f.write("}\n")
    f.write("@end\n")

    print(", ".join(formattedBytes))

def main(argv):
  inputFile = ''
  outputClass = 'ImageCode'
  outputDir = os.getcwd()

  try:
    opts, args = getopt.getopt(argv,"hi:c:o:")
  except getopt.GetoptError:
    print('image_to_code.py -i <inputFile> [-c <class>] [-o <outputDir>]')
    sys.exit(2)
  for opt, arg in opts:
    if opt == '-h':
      print('image_to_code.py -i <inputFile> [-c <class>] [-o <outputDir>]')
      sys.exit()
    elif opt == '-i':
      inputFile = arg
    elif opt == '-c':
      outputClass = arg
    elif opt in '-o':
      outputDir = arg

  # Build file headers
  header = headerTemplate % {"args" : " ".join(argv)}

  # outputClass needs to add PNG as part of it
  outputClass = outputClass + "PNG"

  # Build the output base filename
  outputFileBase = outputDir + "/" + outputClass

  # Build .h file
  outputFile = outputFileBase + ".h"
  write_header_file(header, outputClass, outputFile)

  # Build .m file
  outputFile = outputFileBase + ".m"
  write_implementation_file(inputFile, header, outputClass, outputFile)

if __name__ == "__main__":
   main(sys.argv[1:])
