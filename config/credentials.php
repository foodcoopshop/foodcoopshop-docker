<?php
declare(strict_types=1);

/**
 * credentials.default.php
 * please rename this file to "credentials.php" to use it
 *
 * FoodCoopShop - The open source software for your foodcoop
 *
 * Licensed under the GNU Affero General Public License version 3
 * For full copyright and license information, please see LICENSE
 * Redistributions of files must retain the above copyright notice.
 *
 * @since         FoodCoopShop 1.0.0
 * @license       https://opensource.org/licenses/AGPL-3.0
 * @author        Mario Rothauer <office@foodcoopshop.com>
 * @copyright     Copyright (c) Mario Rothauer, https://www.rothauer-it.com
 * @link          https://www.foodcoopshop.com
 */

return [

    'app' => [

        /**
         * set to true if you want to receive debug emails when exceptions are triggered
         */
        'emailErrorLoggingEnabled' => false,

        /**
         * TO address
         * when exceptions are triggered, emails are sent TO this email address
         */
        'debugEmail' => 'REPLACEWITHYOUR@MAIL.COM',

        /**
         * this email address
         * - receives the test email of url: /email /admin/configurations/sendTestEmail
         * - must have a valid customer record (which is never shown in customer list)
         * - receives the database dumps of BackupDatabase Shell
         */
        'hostingEmail' => 'REPLACEWITHYOUR@MAIL.COM',

    ],

    /**
     * DEBUG email config
     * emails are sent FROM this email configuration if emailErrorLoggingEnabled is set to true
     * needs to be configured to run BackupDatabaseShell
     */
    'EmailTransport' => [
        'debug' => [
            'className' => 'Smtp',
            'host' => 'ssl://REPLACEWITHYOUR.SERVER.COM',
            'port' => 465,
            'timeout' => 30,
            'username' => 'REPLACEWITHYOUR@MAIL.COM',
            'password' => trim(file_get_contents('/run/secrets/email_pass')), //Email SMTP authentication Docker secret
            'tls' => false, //This refers to opportunistic TLS (STARTTLS)
        ],
    ],
    'Email' => [
        'debug' => [
            /*'emailFormat' => 'html',*/
            'transport' => 'debug',
            'from' => ['REPLACEWITHYOUR@MAIL.COM' => 'REPLACEWITHYOURNAME'], // [email-address => name] syntax necessary (not only [email]
            'charset' => 'utf-8',
            'headerCharset' => 'utf-8',
        ],
    ],

];
