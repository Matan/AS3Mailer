<?php

/**
 * Standard PHP mailer.
 * Built for AS3Mailer.
 *
 * NOTE:
 * All arguments can be passed via post data or url variables.
 * All email address can be given straight e.g. matan@example.com or with name attached e.g. Matan Uberstein <matan@example.com>.
 * NO email validation is done on server side.
 *
 * Required arguments are:
 * @param digest - for security checking, see securityCheck function below.
 * @param from - The source email address. e.g. matan@example.com or Matan Uberstein <matan@example.com>
 * @param to - A comma separated list of destination email addresses.
 * @param subject - The subject of the email.
 * @param type - The format of the email message. Options are: text/html or text/plain.
 * @param mimeVersion - The MIME-Version included in the header of the email.
 *
 * Optional argumetns are:
 * @param cc - A comma separated list of destination email addresses.
 * @param bcc - A comma separated list of destination email addresses.
 * @param charset - The characher encoding of the email messsage. This is required if the type is set ot text/html.
 * @param message - The body of the email, can be in plain text of html format.
 * @param messageURL - The server can load in the email message directly from the url passed.
 */

/* ------------------------------------------------------------------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------------------------------------------------------------------- */

/*
 * Use the $LOCKED variable to lock in any values. This will cause the matching request variable to be ignored.
 * NOTE: variable 'digest' can't be locked/ignored.
 */
$LOCKED = array();
//$LOCKED['from'] = "";
//$LOCKED['to'] = "";
//$LOCKED['subject'] = "";
//$LOCKED['type'] = "";
//$LOCKED['mimeVersion'] = "";
//$LOCKED['cc'] = "";
//$LOCKED['bcc'] = "";
//$LOCKED['charset'] = "";
//$LOCKED['message'] = "";
//$LOCKED['messageURL'] = "";

/*
 * The security check is called after all the arguments have been validated.
 * This ensured that no-one other than you can use your mail script.
 * Please replace "%%--REPLACE_SECRET_WORD--%%" with your own unique string and make sure you call
 * AS3mailer with the exact same string. Do no expose your secret word in anyway! e.g. Loading the
 * secret word from a xml file or any external file is NOT advised as this will expose your secret word.
 * Hard code it into your Flash file, in this manner the only for someone to get your secret word is by
 * decompiling the flash or hacking your server.
 */
function securityCheck() {
    $firstToSplit = explode(",", getValue('to'));
    $toSplit = explode("@", $firstToSplit[0]);
    $firstHalf = strtolower(strrev($toSplit[1]));
    $secondHalf = strtoupper($toSplit[0]);
    $saltedKey = $firstHalf . "%%--REPLACE_SECRET_WORD--%%" . $secondHalf;
    $generatedDigest = sha1($saltedKey);

    return ($_REQUEST['digest'] == $generatedDigest);
}

/* ------------------------------------------------------------------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------------------------------------------------------------------- */
/* ------------------------------------------------------------------------------------------------------------------------------------- */

function getValue($key) {
    if(isset($LOCKED[$key])) {
        return $LOCKED[$key];
    } else {
        return $_REQUEST[$key];
    }
}

function hasValue($key) {
    if(isset($LOCKED[$key])) {
        return true;
    } else {
        return isset($_REQUEST[$key]);
    }
}

if(!isset($_REQUEST['digest']) && hasValue('from') && hasValue('to') && hasValue('subject') && hasValue('mimeVersion') && hasValue('type')) {
    echo 'Required variables not set!';
    exit();
}

if(!hasValue('message') && !hasValue('messageURL')) {
    echo 'Param "message" or "messageURL" must be set!';
    exit();
}

if(!securityCheck()) {
    echo 'Security check failed.';
    exit();
}

if(getValue('type') == 'text/html' || getValue('type') == 'text/plain') {
    if(getValue('type') == 'text/html' && !hasValue('charset')) {
        echo 'If mail type set to "text/html", a Charset must be defined.';
        exit();
    }
    if(hasValue('message')) {
        $message = getValue('message');
    } else {
        $message = "";
        try {
            $fh = fopen(getValue('messageURL'), 'r');
            while(!feof($fh)) {
                $message .= fgets($fh, 4096);
            }
            fclose($fh);
        } catch (Exception $err) {
            echo $err;
            exit();
        }
    }
} else {
    echo 'Mail type not recognized. Options are: "text/html" or "text/plain".';
    exit();
}

$line_break = "\r\n";

// To send HTML mail, the Content-type header must be set
$headers = 'MIME-Version: ' . getValue('mimeVersion') . $line_break;
if(getValue('type') == 'text/html') {
    $headers .= 'Content-type: ' . getValue('type') . '; charset=' . getValue('charset') . $line_break;
}

// Additional headers
$headers .= 'From: ' . getValue('from') . $line_break;
if(hasValue('cc')) {
    $headers .= 'Cc: ' . getValue('cc') . $line_break;
}
if(hasValue('bcc')) {
    $headers .= 'Bcc: ' . getValue('bcc') . $line_break;
}

// Mail it
$success = mail(getValue('to'), getValue('subject'), $message, $headers);
if($success) {
    echo('true');
} else {
    echo('Could not send mail.');
}
?>